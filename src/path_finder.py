import os

# STATS_FILENAME = 'assembly_stats.p'


class PathFinder:
    def __init__(self, main_dir, assembler):
        self.main_dir = os.path.abspath(main_dir)
        self.assembler = assembler

    def get_study_dir(self, pacc):
        return os.path.join(self.main_dir, pacc[0:7], pacc)

    def get_run_dir(self, study_dir, run_accession):
        return os.path.join(study_dir, run_accession[0:7], run_accession, self.assembler, '001')

    def get_raw_dir(self, study_dir):
        return os.path.join(study_dir, 'raw')

    def get_tmp_dir(self, study_dir, run_accession):
        return os.path.join(study_dir, 'tmp', run_accession[0:7], run_accession, self.assembler, '001')


        # def get_all_studies(self):
        #     # Find Dirs with format of
        #     folders = list(filter(util.study_container_reg.search, os.listdir(self.main_dir)))
        #     studies = []
        #     for folder in folders:
        #         studies.extend(os.listdir(os.path.join(self.main_dir, folder)))
        #     return studies
        # def get_study_runs(self, study_dir):
        #     run_accessions = []
        #     for run_container in list(filter(util.run_container_reg.search, os.listdir(study_dir))):
        #         run_accessions.extend(list(filter(util.run_id_reg_no_anchors.search,
        #                                           os.listdir(os.path.join(study_dir, run_container)))))
        #     return run_accessions
        # def get_study_assembled_runs(self, study_dir):
        #     assembly_paths = ",".join(self.get_study_assembly_paths(study_dir))
        #     runs = self.get_study_runs(study_dir)
        #     return list(filter(lambda run_acc: run_acc in assembly_paths, runs))
        # def get_fasta_path(self, study_dir, run_accession):
        #     return os.path.join(self.get_run_dir(study_dir, run_accession), 'contigs.fasta')
        # Return paths of completed assemblies
        # def get_study_assembly_paths(self, study_dir):
        #     assembly_paths = []
        #     run_containers = get_run_container_dirs(study_dir)
        #     for run_container in run_containers:
        #         assembly_paths.extend(
        #             glob.glob(os.path.join(study_dir, run_container, '*', self.assembler, '001', 'contigs.fasta')))
        #     return assembly_paths
        #
        # Return paths of completed assemblies
        # def get_study_assembly_stats_paths(self, study_dir):
        #     assembly_paths = []
        #     run_containers = get_run_container_dirs(study_dir)
        #     for run_container in run_containers:
        #         assembly_paths.extend(
        #             glob.glob(os.path.join(study_dir, run_container, '*', self.assembler, '001', STATS_FILENAME)))
        #     return assembly_paths
        #
        # def get_assembly_stats_file(self, study_dir, run_accession):
        #     run_dir = self.get_run_dir(study_dir, run_accession)
        #     return os.path.join(run_dir, STATS_FILENAME)
        #
        # def get_upload_dir(self, study_dir):
        #     return os.path.join(study_dir, 'upload')
        #
        # def get_tmp_dir(self, study_dir, run_id):
        #     return os.path.join(study_dir, 'tmp', run_id)
        #
        # def get_log_dir(self, study_dir):
        #     return os.path.join(study_dir, 'logs')
        #
        #
        # def get_study_downloaded_file(self, study_dir):
        #     return os.path.join(study_dir, 'downloaded.txt')
        #
        # def get_assembly_log_file(self, study_dir, run_accesssion):
        #     lsf_file = os.path.join(self.get_log_dir(study_dir), run_accesssion)
        #     # TODO change behaviour when introducing megahit / minia
        #     list_of_files = glob.glob(lsf_file + '*')
        #     if len(list_of_files) > 0:
        #         latest_file = max(list_of_files, key=os.path.getctime)
        #         if os.path.isfile(latest_file):
        #             return latest_file
        #     raise IOError('Could not find log file for: ' + run_accesssion)
        #
        # def get_raw_run_files(self, study_dir, run_id):
        #     raw_dir = os.path.join(self.main_dir, study_dir, self.get_raw_dir(study_dir), '*')
        #     return list(filter(lambda f: run_id in f, glob.glob(raw_dir)))
        #
        # def get_numbered_raw_run_files(self, study_dir, run_id):
        #     raw_dir = os.path.join(self.main_dir, study_dir, self.get_raw_dir(study_dir), '*')
        #     return list(filter(lambda f: run_id in f and ('_1' in f or '_2' in f), glob.glob(raw_dir)))
        #
        # def get_study_desc_file(self, study_id):
        #     return os.path.join(self.get_study_dir(study_id), study_id + '.txt')
        #
        # def get_study_json_file(self, study_id):
        #     return os.path.join(self.get_study_dir(study_id), study_id + '.json')
        #
        # def get_compressed_assembly(self, study_id, run_id):
        #     return os.path.join(self.get_run_dir(self.get_study_dir(study_id), run_id), run_id + '.fasta.gz')
        #
        # def get_compressed_assembly_md5(self, study_id, run_id):
        #     return self.get_compressed_assembly(study_id, run_id) + '.md5'
        #
        # def get_minia_input_file(self, study_dir, run_id):
        #     if self.assembler == 'minia':
        #         return os.path.join(self.get_run_dir(study_dir, run_id), 'in.txt')
        #     else:
        #         raise ValueError('Cannot use minia input file with assembler other than minia.')
        #
        # def get_run_assembly(self, study_dir, run_id):
        #     run_dir = self.get_run_dir(study_dir, run_id)
        #     if self.assembler in ('metaspades', 'megahit'):
        #         filename = 'contigs.fasta'
        #     elif self.assembler == 'minia':
        #         filename = 'contigs.fa'
        #     else:
        #         raise ValueError('Assembler {} not allowed'.format(self.assembler))
        #     return os.path.join(run_dir, filename)

#
#
# def get_run_container_dirs(study_dir):
#     return list(filter(util.run_container_reg.search, os.listdir(study_dir)))
