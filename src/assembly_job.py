import os
from ruamel import yaml
import subprocess
import logging

from util import Assembler
from download_manager import DownloadManager

job_template_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, 'cwl', 'job_templates'))
job_templates = {
    'metaspades_paired': os.path.join(job_template_dir, 'metaspades_paired.yml'),
    # 'metaspades_interleaved': os.path.join(job_template_dir, 'metaspades_interleaved.yml'),
    'spades_paired': os.path.join(job_template_dir, 'spades_paired.yml'),
    'spades_single': os.path.join(job_template_dir, 'spades_single.yml')
}
pipeline_workflows_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, 'cwl'))
pipeline_workflows = {
    Assembler.metaspades: os.path.join(pipeline_workflows_dir, 'metaspades_pipeline.cwl'),
    Assembler.spades: os.path.join(pipeline_workflows_dir, 'spades_pipeline.cwl')
}

TEMPLATE_NAME = 'job_config.yml'


def safe_make_dir(dirname):
    if not os.path.exists(dirname):
        os.makedirs(dirname)


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
        logging.info('\tLaunching pipeline')
        self.launch_pipeline()
        logging.info('\tFinished!')

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
        if self.assembler == Assembler.metaspades:
            self.write_metaspades_job()
        elif self.assembler == Assembler.megahit:
            self.write_megahit_job()
        elif self.assembler == Assembler.spades:
            self.write_spades_job()
        else:
            raise ValueError('Assembler {} not supported.'.format(self.assembler))

    def write_metaspades_job(self):
        if self.run['library_layout'] == 'PAIRED':
            self.write_template(job_templates['metaspades_paired'])
        else:
            raise NotImplementedError('Assemblies using metaspades in non-paired mode are not yet supported')

    def write_spades_job(self):
        if self.run['library_layout'] == 'SINGLE':
            self.write_template(job_templates['spades_single'])
        elif self.run['library_layout'] == 'PAIRED':
            self.write_template(job_templates['spades_paired'])
        else:
            raise NotImplementedError('Assemblies using metaspades in paired mode are not yet supported')

    def write_megahit_job(self):
        if self.run.library_layout == 'paired':
            self.write_template(job_templates['megahit_paired'])
        else:
            raise NotImplementedError('Assemblies using metaspades in non-paired mode are not yet supported')
        pass

    def write_template(self, template_src):
        with open(template_src, 'r') as f:
            template = yaml.safe_load(f)
        template['run_id'] = str(self.run['run_accession'])
        raw_files = sorted(self.download_logger.logged_downloads)
        template['forward_reads']['path'] = str(os.path.join(self.raw_dir, raw_files[0]))
        template['reverse_reads']['path'] = str(os.path.join(self.raw_dir, raw_files[1]))
        # template['cwltool:overrides'][self.assembler.__str__() + '.cwl']['requirements']['ResourceRequirement'] = {
        #     'ramMin': self.memory,
        #     'coresMin': self.cores
        # }
        # PENDING CWLTOOL UPDATE IN TOIL
        with open(self.job_desc_file, 'w+') as f:
            yaml.dump(template, f)

    def create_pipeline_cmd(self):
        # return f'cwltoil --user-space-docker-cmd=udocker --cleanWorkDir onSuccess --debug
        # --outdir out --tmpdir tmp --workDir toil_work --batchSystem lsf megahit_pipeline.cwl megahit_pipeline.yml'
        return 'cwltoil  --cleanWorkDir onSuccess  --debug  --outdir {}  --workDir {}  {} {}'.format(
            self.run_dir, os.getcwd(), self.pipeline_workflow, self.job_desc_file)

    def launch_pipeline(self):
        cmd = self.create_pipeline_cmd()
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
        process.wait()
        return process.returncode

    def __repr__(self):
        return 'Study: {}\n'.format(self.study_accession) + \
               'Accessions: {}\n'.format(self.run['run_accession'])