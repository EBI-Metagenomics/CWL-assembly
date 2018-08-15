import os
from ruamel import yaml
import subprocess
import logging

from util import Assembler
from download_manager import DownloadManager

job_template_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir, 'cwl', 'job_templates'))
job_templates = {
    'metaspades_paired': os.path.join(job_template_dir, 'metaspades_paired.yml'),
    'metaspades_interleaved': os.path.join(job_template_dir, 'metaspades_interleaved.yml'),
    'spades_paired': os.path.join(job_template_dir, 'spades_paired.yml'),
    'spades_interleaved': os.path.join(job_template_dir, 'spades_interleaved.yml'),
    'spades_single': os.path.join(job_template_dir, 'spades_single.yml'),
    'megahit_paired': os.path.join(job_template_dir, 'megahit_paired.yml'),
    'megahit_interleaved': os.path.join(job_template_dir, 'megahit_interleaved.yml'),
    'megahit_single': os.path.join(job_template_dir, 'megahit_single.yml')
}
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
        self.cores = 32 if args.memory >= 240 else 16
        self.assembler = args.assembler
        # Fetch run data, remove duplicate runs, flatten list
        self.run = run
        self.study_accession = run['secondary_study_accession']
        self.raw_files = []

        self.process = None

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
            if len(self.download_logger.logged_downloads) == 1:
                template = 'metaspades_interleaved'
            else:
                template = 'metaspades_paired'
            self.write_template(job_templates[template])
        else:
            raise NotImplementedError('Assemblies using metaspades in non-paired mode are not yet supported')

    def write_spades_job(self):
        if self.run['library_layout'] == 'PAIRED':
            if len(self.download_logger.logged_downloads) == 1:
                template = 'spades_interleaved'
            else:
                template = 'spades_paired'
        else:
            template = 'spades_single'
        self.write_template(job_templates[template])

    def write_megahit_job(self):
        if self.run['library_layout'] == 'PAIRED':
            if len(self.download_logger.logged_downloads) == 1:
                template = 'megahit_interleaved'
            else:
                template = 'megahit_paired'
        else:
            template = 'megahit_single'
        self.write_template(job_templates[template])

    def write_template(self, template_src):
        with open(template_src, 'r') as f:
            template = yaml.safe_load(f)
        template['output_assembly_name'] = str(self.run['run_accession'])
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
        return 'cwltoil  --retryCount 1 --user-space-docker-cmd={} --cleanWorkDir onSuccess --outdir {} --debug --workDir {}  {} {} '.format(
            self.docker_cmd, self.run_dir, os.getcwd(), self.pipeline_workflow, self.job_desc_file)

    def launch_pipeline(self):
        cmd = self.create_pipeline_cmd()
        with open(self.toil_log_file, 'wb') as logfile:
            # self.process = subprocess.Popen(cmd, stdout=logfile, stderr=logfile, shell=True)
            self.process = subprocess.Popen(cmd, stdout=subprocess.PIPE, shell=True)
        print('Launching pipeline {} {}'.format(self.study_accession, self.run['run_accession']))
        return self

    def __repr__(self):
        return 'Study: {}\n'.format(self.study_accession) + \
               'Accessions: {}\n'.format(self.run['run_accession'])
