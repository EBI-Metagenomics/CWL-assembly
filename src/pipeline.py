import argparse
import logging
from enum import Enum
import os.path
from src import ena_api, download
from ruamel.yaml import YAML
import subprocess

from src.path_finder import PathFinder


def is_valid_file(parser, arg):
    if not os.path.exists(arg):
        parser.error("Input file %s does not exist!" % arg)
    else:
        return open(arg, 'r')  # return an open file handle


class Assembler(Enum):
    metaspades = 'metaspades'
    spades = 'spades'
    megahit = 'megahit'

    def __str__(self):
        return self.value


job_template_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, 'cwl', 'job_templates'))
job_templates = {
    'metaspades_paired': os.path.join(job_template_dir, 'metaspades_paired.yml'),
    'spades_paired': os.path.join(job_template_dir, 'spades_paired.yml'),
    'spades_single': os.path.join(job_template_dir, 'spades_single')
}
pipeline_workflows_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, 'cwl'))
pipeline_workflows = {
    Assembler.metaspades: os.path.join(pipeline_workflows_dir, 'metaspades_pipeline.cwl'),
    Assembler.spades: os.path.join(pipeline_workflows_dir, 'spades_pipeline.cwl')
}

TEMPLATE_NAME = 'job_config.yml'


class AssemblyJob:
    def __init__(self, path_finder, ena, args, run):
        self.ena = ena
        self.memory = args.memory
        self.cores = 32 if args.memory >= 240 else 16
        self.assembler = args.assembler
        # Fetch run data, remove duplicate runs, flatten list
        self.run = run
        self.study_accession = run['secondary_study_accession']
        self.raw_files = []

        self.study_dir = path_finder.get_study_dir(run['secondary_study_accession'])
        self.run_dir = path_finder.get_run_dir(self.study_dir, run['run_accession'])
        self.raw_dir = path_finder.get_raw_dir(self.study_dir)
        self.tmp_dir = path_finder.get_tmp_dir(self.study_dir, run['run_accession'])
        self.job_desc_file = os.path.join(self.run_dir, TEMPLATE_NAME)
        self.pipeline_workflow = pipeline_workflows[self.assembler]

    def create_dirs(self):
        os.makedirs(self.study_dir, exist_ok=True)
        os.makedirs(self.run_dir, exist_ok=True)
        os.makedirs(self.raw_dir, exist_ok=True)
        os.makedirs(self.tmp_dir, exist_ok=True)
        return self

    def download_raw_data(self):
        run_accession = self.run['run_accession']
        if ';' in self.run['submitted_ftp']:
            files = (run_accession + '_1.fastq.gz', run_accession + '_2.fastq.gz')
        else:
            files = (run_accession + '.fastq.gz')
        filepaths = [os.path.join(self.raw_dir, file) for file in files]
        downloads = list(zip(self.run['submitted_ftp'].split(';'), filepaths))
        download.download_urls(downloads)
        self.raw_files.extend(filepaths)
        return self

    def write_job(self):
        if self.assembler == Assembler.metaspades:
            self.write_metaspades_job()
        elif self.assembler == Assembler.megahit:
            self.write_megahit_job()
        elif self.assembler == Assembler.spades:
            self.write_spades_job()
        else:
            raise ValueError(f'Assembler {self.assembler} not supported.')
        return self

    def write_metaspades_job(self):
        if self.run['library_layout'] == 'PAIRED':
            self.write_template(job_templates['metaspades_paired'])
        else:
            raise NotImplementedError('Assemblies using metaspades in non-paired mode are not yet supported')

    def write_spades_job(self):
        if self.run['library_layout'] == 'PAIRED':
            self.write_template(job_templates['spades_paired'])
        elif self.run['library_layout'] == 'SINGLE':
            self.write_template(job_templates['spades_single'])
        else:
            raise NotImplementedError('Assemblies using metaspades in non-paired mode are not yet supported')

    def write_megahit_job(self):
        # if self.run.library_layout == 'paired':
        #     self.write_template(job_templates['megahit_paired'])
        # else:
        #     raise NotImplementedError('Assemblies using metaspades in non-paired mode are not yet supported')
        pass

    def write_template(self, template_src):
        yaml = YAML(typ='safe')
        with open(template_src, 'r') as f:
            template = yaml.load(f)
        template['run_id'] = self.run['run_accession']
        template['forward_reads']['path'] = self.raw_files[0]
        template['reverse_reads']['path'] = self.raw_files[1]
        # template['cwltool:overrides'][self.assembler.__str__() + '.cwl']['requirements']['ResourceRequirement'] = {
        #     'ramMin': self.memory,
        #     'coresMin': self.cores
        # }
        # PENDING CWLTOOL UPDATE IN TOIL
        with open(self.job_desc_file, 'w+') as f:
            yaml.dump(template, f)

    def create_pipeline_cmd(self):
        # return f'cwltoil --user-space-docker-cmd=udocker --cleanWorkDir onSuccess --debug --outdir out --tmpdir tmp --workDir toil_work --batchSystem lsf megahit_pipeline.cwl megahit_pipeline.yml'
        return f'cwltoil ' \
               f'--cleanWorkDir onSuccess ' \
               f'--debug ' \
               f'--outdir {self.run_dir} ' \
               f'--workDir {os.getcwd()} ' \
               f'{self.pipeline_workflow} {self.job_desc_file}'

    def launch_pipeline(self):
        cmd = self.create_pipeline_cmd()
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
        process.wait()
        return process.returncode

    def __repr__(self):
        return 'Study: {}\n'.format(self.study_accession) + \
               'Accessions: {}\n'.format(self.run['run_accession'])


def clean_input_row(row):
    row = row.strip()
    return row.split(' ')


def get_job_runs(ena, job_accessions):
    runs = []
    for accession in job_accessions:
        runs.extend(get_runs_from_accession(ena, accession))
    return runs


# Used to define co-assembly: each row in input file lists all accessions which will be used in assembly
# def get_jobs_from_file(ena, args):
#     input_jobs = list(map(clean_input_row, args.file.readlines()))
#     args.file.close()
#     input_job_runs = list(map(lambda j: get_job_runs(ena, j), input_jobs))
#     return list(map(lambda accessions: AssemblyJob(ena, args, accessions), input_job_runs))


def get_runs_from_accession(ena, accession):
    if 'P' in accession:
        return ena.get_study_runs(accession, args.ignore_filter)
    elif 'R' in accession:
        accession = ena.get_run_metadata(accession, args.ignore_filter)
        return [accession] or []
    else:
        return []


def get_jobs_from_args(path_finder, ena, args):
    input_job_runs = ena.get_study_runs(args.study, args.ignore_filter)
    if args.runs:
        runs = args.runs.split(',')
        input_job_runs = list(filter(lambda r: r['run_accession'] in runs, input_job_runs))
    return [AssemblyJob(path_finder, ena, args, run) for run in input_job_runs]


def parse_args():
    parser = argparse.ArgumentParser(description='Metagenomic assembly pipeline kickoff script')
    parser.add_argument('assembler', type=Assembler, choices=list(Assembler))
    parser.add_argument('--private', action='store_true')
    parser.add_argument('-m', '--memory', default=240, type=int, help='Memory allocation for pipeline (GB)')
    parser.add_argument('-d', '--dir', default='.', help='Root directory in which to run assemblies')
    parser.add_argument('-s', '--study', help='ENA project accession')
    parser.add_argument('-r', '--runs',
                        help='comma-seperated ENA run accessions to assemble (1 assembly per run) in specified project')
    # data_inputs = parser.add_mutually_exclusive_group()
    # single_projects = data_inputs.add_argument_group()
    # single_projects.add_argument('-s', '--study', help='ENA project accession')
    # single_projects.add_argument('-r', '--runs', help='comma-seperated ENA run accessions in specified project')

    # data_inputs.add_argument('-f', '--file', type=lambda x: is_valid_file(parser, x))

    parser.add_argument('-i', '--ignore_filter', action='store_true',
                        help='Ignore filtering of runs which are not metagenomic or are amplicon')
    return parser.parse_args()


def main(args):
    path_finder = PathFinder(args.dir, args.assembler.__str__())
    ena = ena_api.EnaApiHandler()
    assemblies = get_jobs_from_args(path_finder, ena, args)
    for assembly in assemblies:
        print('Starting assembly')
        assembly.create_dirs()
        print('\tCreated dirs')
        print('\tDownloading raw data')
        assembly.download_raw_data()
        print('\tFinished downloading raw data')
        assembly.write_job()
        print('\tWrote CWL job description')
        print('\tLaunching pipeline')
        assembly.launch_pipeline()
        print('\tFinished!')


if __name__ == '__main__':
    args = parse_args()
    main(args)
