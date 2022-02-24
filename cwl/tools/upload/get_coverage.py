import os
import datetime as dt
import subprocess
import logging
import shutil
import re
import argparse
import glob

reg = 'Num reads:(\d+).*Num.*Bases: (\d+)'
script_path = 'kseq_fastq_base'

SAM_TOOLS = 'samtools'
BWA = 'bwa'
METABAT = 'jgi_summarize_bam_contig_depths'

OUTPUT_FILE = 'coverage.tab'


class CoverageGenError(Exception):
    pass


def get_counts(filepaths):
    outputs = [str(subprocess.check_output([script_path, filepath]), 'utf-8') for filepath in filepaths]
    reg_results = [re.findall(reg, output)[0] for output in outputs]
    return [{'read_count': reg_result[0], 'base_count': reg_result[1]} for reg_result in reg_results]


def get_run_counts(filepaths):
    counts = get_counts(filepaths)
    total_base = sum([int(count['base_count']) for count in counts])
    return {
        'read_count': counts[0]['read_count'],
        'base_count': total_base
    }

def exec_cmd(cmd):
    logging.info('Executing: ' + cmd)
    print('Executing: ' + cmd)
    process = subprocess.Popen(cmd, shell=True)
    process.wait()
    if process.returncode != 0:
        raise CoverageGenError()

def gen_coverage_files(run_accession, fasta_path, raw_files, refresh=False):
    d = os.path.split(fasta_path)[0]
    coverage_dir = os.path.join(d, (run_accession + 'coverage'))
    output_file = os.path.abspath(os.path.join(coverage_dir, OUTPUT_FILE))
    if refresh:
        if os.path.exists(coverage_dir):
            shutil.rmtree(coverage_dir)
        if os.path.exists(output_file):
            os.remove(output_file)

    if os.path.isfile(output_file) and not refresh:
        logging.info('Coverage file already exists for ' + run_accession)
        return output_file
    else:
        logging.info('Generating coverage file for ' + run_accession)

    if not os.path.exists(coverage_dir):
        os.mkdir(coverage_dir)

    prev_dir = os.getcwd()
    os.chdir(coverage_dir)

    # 1. index reference genome
    logging.debug('Indexing reference genome')

    reference = os.path.basename(fasta_path)
    cmd = BWA + " index ../" + reference
    exec_cmd(cmd)

    if not os.path.isfile('sorted.bam'):
        if not os.path.isfile('unsorted.bam'):
            logging.debug('Mapping reads to fasta assembly')
            # 2. map reads to fasta assembly
            bwa_mem_files = raw_files
            cmd = BWA + " mem -t 4 ../{} {} | samtools view -uS - -o unsorted.bam".format(reference,
                                                                                     " ".join(sorted(bwa_mem_files)))
            exec_cmd(cmd)
        else:
            logging.info('Found existing unsorted.bam file')

        logging.debug('Sorting mapping file')
        # 3. sort mapping file
        cmd = SAM_TOOLS + " sort -@ 4 unsorted.bam -o sorted.bam"
        exec_cmd(cmd)
    else:
        logging.info('Found existing sorted.bam files.')

    logging.debug('Indexing mapping file')
    # 4. index mapping file
    cmd = SAM_TOOLS + " index sorted.bam"
    exec_cmd(cmd)

    logging.debug('Calculating coverage depth per contig')
    # 5. calculate coverage depth per contig
    cmd = METABAT + " --outputDepth " + output_file + " sorted.bam "
    exec_cmd(cmd)

    return output_file, coverage_dir

def calc_assembled_pairs(coverage_file):
    with open(coverage_file, 'r') as f:
        assembled_pairs = 0
        assembly_length = 0
        lines = iter(f)
        _ = next(lines)
        for l in f:
            line = l.split()
            length = float(line[1])
            read_depth = float(line[2])
            assembled_pairs += (length * read_depth)
            assembly_length += length
    return assembled_pairs, assembly_length

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Output coverage and stats without required directory structure")
    parser.add_argument("--run_accession", dest="run", help="ENA", required=True)
    parser.add_argument("--fasta_path", dest="contig_path", help="path to contig file")
    parser.add_argument("--raw_dir", dest="raw_path", help="path to raw file directory", required=True)
    parser.add_argument('--refresh', action='store_true',
                        help='Refresh stored cached statistics about assembly results.')
    args = parser.parse_args()
    
    #raw_files = list(filter(lambda f: args.run in f and ('_1' in f or '_2' in f), glob.glob(args.raw_path)))
    raw_files = [os.path.abspath(os.path.join(args.raw_path, p)) for p in os.listdir(args.raw_path)]
    print(raw_files)
    if len(raw_files) == 0:
        logging.error(f'raw files for {args.run} not in {args.raw_path}')
        raise CoverageGenError
    coverage_file, coverage_dir = gen_coverage_files(args.run, args.contig_path, raw_files, refresh=args.refresh)
    assembled_pairs, assembly_length = calc_assembled_pairs(coverage_file)
    run_stats = get_run_counts(raw_files)
    input_base_count = int(run_stats['base_count'])
    print(input_base_count)
    print(assembled_pairs)
    print(assembly_length)
    coverage_depth = assembled_pairs / assembly_length
    with open((args.run + '.coverage'), 'w') as cov_out:
        cov_out.write(f'{args.run}\t{str(coverage_depth)}\n')
    
