import os
import hashlib
import sys
import argparse
import logging
from ena_portal_api.ena_handler import EnaApiHandler

handler = EnaApiHandler()


def parse_args(argv):
    parser = argparse.ArgumentParser(
        description="independent to directory structure")
    parser.add_argument('--data', help='tab separated file format - run_id\tsample\tseq_platform')
    parser.add_argument('--cov_data', help='tab separated file format - run_id\tcoverage')
    parser.add_argument('--assembler', help='assembler name e.g. metaspades')
    parser.add_argument('--version', help='assembler version e.g. 3.14.1')
    parser.add_argument('--assembly_study', help='new registered study id. Must exist in the webin account')
    return parser.parse_args(argv)


def parse_info(data_file, coverage_file):
    assembly_data = {}
    with open(data_file, 'r') as metadata, open(coverage_file, 'r') as cov_data:
        header = metadata.readline()
        for line in cov_data:
            data = line.rstrip().split('\t')
            run_id = data[0]
            coverage = data[1]
            assembly_data[run_id] = [coverage]
        for line in metadata:
            data = line.rstrip().split('\t')
            run_id = data[0]
            sample = data[1]
            instrument = data[2]  
            assembly_data[run_id].append(sample)
            assembly_data[run_id].append(instrument)                                        
    return assembly_data


def get_md5(path_to_file):
    md5_hash = hashlib.md5()
    with open(path_to_file, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            md5_hash.update(chunk)
    return md5_hash.hexdigest()


class IndependentUpload:
    def __init__(self, argv=sys.argv[1:]):
        self.args = parse_args(argv)
        self.metadata = parse_info(self.args.data, self.args.cov_data)
        #self.metadata = []
        #for run in self.assembly_data.keys():
        #    self.metadata.append(handler.get_run(run_accession=run))
        self.assembler = self.args.assembler + ' v'+self.args.version
        self.new_project = self.args.assembly_study
        self.upload_dir = os.path.join(os.getcwd(), 'upload')
        if not os.path.exists(self.upload_dir):
            os.makedirs(self.upload_dir)

    def generate_manifest(self, new_project_id, upload_dir, run_id, sample, coverage, sequencer):
        logging.info('Writing manifest for ' + run_id)
        assembly_file = run_id + '.fasta.gz'
        assembly_path = os.path.join(os.getcwd(), assembly_file)
        assembly_alias = get_md5(assembly_path)
        manifest_path = os.path.join(upload_dir, f'{run_id}.manifest')
        values = (
            ('STUDY', new_project_id),
            ('SAMPLE', sample),
            ('RUN_REF', run_id),
            ('ASSEMBLYNAME', run_id+'_'+assembly_alias),
            ('ASSEMBLY_TYPE', 'primary metagenome'),
            ('COVERAGE', coverage),
            ('PROGRAM', self.assembler),
            ('PLATFORM', sequencer),
            ('FASTA', assembly_path),
            ('TPA', 'true')
        )
        print("Writing manifest file (.manifest) for " + run_id)
        with open(manifest_path, "w") as outfile:
            for (k, v) in values:
                manifest = f'{k}\t{v}\n'
                outfile.write(manifest)

    def write_manifests(self):
        #run = [coverage, sample, instrument]
        for run, value in self.metadata.items():
            self.generate_manifest(self.new_project, self.upload_dir, run, value[1], value[0], value[2])


if __name__ == "__main__":
    gen_manifest = IndependentUpload()
    gen_manifest.write_manifests()
    logging.info('Completed')
