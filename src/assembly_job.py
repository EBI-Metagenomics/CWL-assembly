import os
from ruamel import yaml
import subprocess
import logging

from util import Assembler
from download_manager import DownloadManager

job_template_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, 'cwl', 'job_templates'))


def get_job_template(template_name):
    return os.path.join(job_template_dir, template_name + '.yml')


pipeline_workflows_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, 'cwl'))
pipeline_workflows = {
    Assembler.metaspades: os.path.join(pipeline_workflows_dir, 'metaspades_pipeline.cwl'),
    Assembler.spades: os.path.join(pipeline_workflows_dir, 'spades_pipeline.cwl'),
    Assembler.megahit: os.path.join(pipeline_workflows_dir, 'megahit_pipeline.cwl')
}

TEMPLATE_NAME = 'job_config.yml'


def safe_make_dir(dirname):
    if not os.path.exists(dirname):
        os.makedirs(dirname)


class AssemblyJob:
    def __init__(self, path_finder, ena, args, run):
        self.docker_cmd = args.docker_cmd
        self.ena = ena
        self.memory = args.memory
        self.cores = args.cores
        self.assembler = args.assembler
        self.assembly_name = run['run_accession']
        # Fetch run data, remove duplicate runs, flatten list
        self.run = run
        self.study_accession = run['secondary_study_accession']

        self.process = None
        self.batch_system = args.batch_system

        self.study_dir = path_finder.get_study_dir(run['secondary_study_accession'])
        self.run_dir = path_finder.get_run_dir(self.study_dir, run['run_accession'])
        self.raw_dir = path_finder.get_raw_dir(self.study_dir)
        self.tmp_dir = path_finder.get_tmp_dir(self.study_dir, run['run_accession'])
        self.job_desc_file = os.path.join(self.run_dir, TEMPLATE_NAME)
        self.pipeline_workflow = pipeline_workflows[self.assembler]

        self.toil_log_file = path_finder.get_toil_log_file(self.run_dir)

        download_log_file = os.path.join(self.study_dir, 'downloads.yml')
        self.download_logger = DownloadManager(download_log_file, self.raw_dir)
        logging.info('Starting assembly')
        self.create_dirs()
        logging.info('\tCreated dirs')
        logging.info('\tDownloading raw data')
        self.download_raw_data()
        logging.info('\tFinished downloading raw data')
        self.write_job()
        logging.info('\tWrote CWL job description')

    def create_dirs(self):
        safe_make_dir(self.study_dir)
        safe_make_dir(self.run_dir)
        safe_make_dir(self.raw_dir)
        safe_make_dir(self.tmp_dir)

    def download_raw_data(self):
        dest_paths = map(lambda x: os.path.join(self.raw_dir, os.path.basename(x)), self.run['fastq_ftp'].split(';'))
        downloads = list(zip(self.run['fastq_ftp'].split(';'), dest_paths))
        with self.download_logger:
            self.download_logger.download_urls(downloads)

    def write_job(self):
        if self.run['library_layout'] == 'PAIRED':
            if len(self.download_logger.logged_downloads) == 1:
                template = '_interleaved'
            else:
                template = '_paired'
        elif self.assembler != Assembler.metaspades:
            template = '_single'
        else:
            raise NotImplementedError('Assemblies using metaspades in non-paired mode are not yet supported')
        self.write_template(get_job_template(str(self.assembler) + template))

    def write_requirements(self, template):
        template['cwltool:overrides']['assembly/' + self.assembler.__str__() + '.cwl']['requirements'][
            'ResourceRequirement'] = {
            'ramMin': self.memory,
            'coresMin': self.cores
        }

    def write_template(self, template_src):
        with open(template_src, 'r') as f:
            template = yaml.safe_load(f)
        template['output_assembly_name'] = str(self.assembly_name)
        raw_files = sorted(self.download_logger.logged_downloads)
        if template.get('forward_reads'):
            template['forward_reads']['path'] = str(os.path.join(self.raw_dir, raw_files[0]))
            template['reverse_reads']['path'] = str(os.path.join(self.raw_dir, raw_files[1]))
        elif template.get('interleaved_reads'):
            template['interleaved_reads']['path'] = str(os.path.join(self.raw_dir, raw_files[0]))
        elif template.get('single_reads'):
            template['single_reads']['path'] = str(os.path.join(self.raw_dir, raw_files[0]))
        else:
            raise NotImplementedError('No valid fields for reads found in template {}'.format(template_src))

        self.write_requirements(template)

        with open(self.job_desc_file, 'w+') as f:
            yaml.dump(template, f)

    def create_pipeline_cmd(self):
        batch_system = ''
        if self.batch_system:
            batch_system = '--batchSystem ' + self.batch_system
        return 'cwltoil {} --retryCount 1 --user-space-docker-cmd={} --cleanWorkDir onSuccess --outdir {} --logWarning --workDir {}  {} {} '.format(
            batch_system, self.docker_cmd, self.run_dir, self.tmp_dir, self.pipeline_workflow, self.job_desc_file)

    def launch_pipeline(self):
        cmd = self.create_pipeline_cmd()
        print(cmd)
        with open(self.toil_log_file, 'wb') as logfile:
            self.process = subprocess.Popen(cmd, stdout=logfile, stderr=logfile, shell=True)
            # self.process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        print('Launching pipeline {} {}'.format(self.study_accession, self.assembly_name))
        return self

    def __repr__(self):
        return 'Study: {}\n'.format(self.study_accession) + \
               'Accessions: {}\n'.format(self.run['run_accession'])


class CoAssemblyJob(AssemblyJob):
    def __init__(self, path_finder, ena, args, runs):
        self.docker_cmd = args.docker_cmd
        self.ena = ena
        self.memory = args.memory
        self.cores = args.cores
        self.assembler = args.assembler
        # Fetch run data, remove duplicate runs, flatten list
        self.runs = runs
        self.study_accession = '_'.join(sorted(set(run['secondary_study_accession'] for run in runs)))
        run_accessions = '_'.join(sorted(set(run['run_accession'] for run in runs)))

        self.assembly_name = run_accessions

        self.process = None
        self.study_dir = path_finder.get_study_dir(self.study_accession)
        self.run_dir = path_finder.get_run_dir(self.study_dir, run_accessions)
        self.raw_dir = path_finder.get_raw_dir(self.study_dir)
        self.tmp_dir = path_finder.get_tmp_dir(self.study_dir, run_accessions)
        self.job_desc_file = os.path.join(self.run_dir, TEMPLATE_NAME)
        self.pipeline_workflow = pipeline_workflows[self.assembler]

        self.toil_log_file = path_finder.get_toil_log_file(self.run_dir)

        download_log_file = os.path.join(self.study_dir, 'downloads.yml')
        self.download_logger = DownloadManager(download_log_file, self.raw_dir)
        logging.info('Starting assembly')
        self.create_dirs()
        logging.info('\tCreated dirs')
        logging.info('\tDownloading raw data')
        self.download_raw_data()
        logging.info('\tFinished downloading raw data')
        self.write_job()
        logging.info('\tWrote CWL job description')

    def download_raw_data(self):
        fastq_urls = [url for run in self.runs for url in run['fastq_ftp'].split(';')]
        dest_paths = map(lambda x: os.path.join(self.raw_dir, os.path.basename(x)), fastq_urls)
        downloads = list(zip(fastq_urls, dest_paths))
        with self.download_logger:
            self.download_logger.download_urls(downloads)

    def write_job(self):
        if self.assembler != Assembler.megahit:
            raise NotImplementedError('Co-assemblies not supported for assemblers other than megahit.')
        self.write_template(get_job_template(str(self.assembler) + '_coassembly'))

    def get_paired_runs(self):
        return [run for run in self.runs if run['library_layout'] == 'PAIRED' and ';' in run['fastq_ftp']]

    def get_interleaved_runs(self):
        return [run for run in self.runs if run['library_layout'] == 'PAIRED' and ';' not in run['fastq_ftp']]

    def get_single_runs(self):
        return [run for run in self.runs if run['library_layout'] == 'SINGLE']

    def map_url_to_file(self, url):
        return str(os.path.join(self.raw_dir, os.path.basename(url)))

    def write_paired_runs(self, template):
        paired_runs = self.get_paired_runs()
        if len(paired_runs) == 0:
            del template['forward_reads']
            del template['reverse_reads']
        else:
            forward_read_files, reverse_reads_files = zip(
                *[sorted(str(run['fastq_ftp']).split(';')) for run in paired_runs])
            template['forward_reads'] = [{'path': self.map_url_to_file(f), 'class': 'File'} for f in forward_read_files]
            template['reverse_reads'] = [{'path': self.map_url_to_file(f), 'class': 'File'} for f in
                                         reverse_reads_files]

    def write_interleaved_runs(self, template):
        interleaved_runs = self.get_interleaved_runs()
        if len(interleaved_runs) == 0:
            del template['interleaved_reads']
        else:
            interleaved_read_files = [str(run['fastq_ftp']) for run in interleaved_runs]
            template['interleaved_reads'] = [{'path': self.map_url_to_file(f), 'class': 'File'} for f in
                                             interleaved_read_files]

    def write_single_runs(self, template):
        single_runs = self.get_single_runs()
        if len(single_runs) == 0:
            del template['single_reads']
        else:
            single_read_files = [str(run['fastq_ftp']) for run in single_runs]
            template['single_reads'] = [{'path': self.map_url_to_file(f), 'class': 'File'} for f in single_read_files]

    def write_template(self, template_src):
        with open(template_src, 'r') as f:
            template = yaml.safe_load(f)
        template['output_assembly_name'] = str(self.assembly_name)

        self.write_paired_runs(template)

        self.write_interleaved_runs(template)

        self.write_single_runs(template)

        self.write_requirements(template)

        with open(self.job_desc_file, 'w+') as f:
            yaml.dump(template, f)
