import gzip
import os
import shutil
import hashlib
import argparse
import re
import subprocess

from Bio import SeqIO


def filter_contig_length(source_file, threshold, assembler, output_file='contigs.stripped.fasta'):
    if assembler in ['spades', 'metaspades']:
        contig_regex = 'NODE_\d+_length_(\d+)_cov_*'
    elif assembler == 'megahit':
        contig_regex = 'k.+flag=.+multi=.+len=(\d+)'
    else:
        raise ValueError('Assembler ' + assembler + ' is not supported')
    assembly_fasta = SeqIO.parse(source_file, 'fasta')

    with open(output_file, "w") as out:
        for line in assembly_fasta:
            current_length = re.findall(contig_regex, line.description)[0]
            if int(current_length) >= int(threshold):
                SeqIO.write(line, out, "fasta")
    return output_file


def get_matched_contigs(blastn):
    contaminant_data = open(blastn, 'r')
    matched_contigs = contaminant_data.read()
    # Retrieve contig name and filter empty string
    return set(filter(bool, {c.split('\t')[0] for c in matched_contigs.split('\n')}))


def filter_sequences(trimmed, blastn, output_file='filtered_contigs.fasta'):
    matched_contig_names = set(get_matched_contigs(blastn))

    # Remove empty strings
    trimmed_fasta = SeqIO.parse(trimmed_file, 'fasta')
    matched_contig_names = set(filter(bool, matched_contig_names))
    with open(output_file, 'w+') as out:
        for line in trimmed_fasta:
            check_contig_header = line.id.strip().replace('>', '')
            if check_contig_header not in matched_contig_names:
                SeqIO.write(line, out, "fasta")

    return output_file


def compress_file(in_file, out_file):
    out_dir = os.path.dirname(out_file)
    if not os.path.exists(out_dir) and len(out_dir) > 0:
        os.makedirs(out_dir)
    with open(in_file, 'rb') as f_in, gzip.open(out_file, 'wb+') as f_out:
        shutil.copyfileobj(f_in, f_out)


def write_md5(compressed_file):
    md5sum = md5(compressed_file)
    with open(compressed_file + '.md5', 'w+') as f:
        f.write(md5sum)


def md5(fname):
    hash_md5 = hashlib.md5()
    with open(fname, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Remove contigs of length < min_contig_length from a fasta file'
                                                 'Remove host and PhiX sequences'
                                                 'Compress final fasta file and generate md5')
    parser.add_argument("-r", "--run_id", help="Run id to prefix final contig file", type=str)
    parser.add_argument("--contig_file", help="Contig file")
    parser.add_argument("--threshold", help='Set min contig length', type=int, default=500)
    parser.add_argument("--blast", help='outputs of blast against contaminants', required=True)
    parser.add_argument('--assembler', choices=['metaspades', 'spades', 'megahit'],
                        help='Assembler used to generate sequence.')
    args = parser.parse_args()

    contig_file = args.contig_file

    trimmed_file = filter_contig_length(contig_file, args.threshold, args.assembler)
    filtered_sequences = filter_sequences(trimmed_file, args.blast)

    final_contig_file = args.run_id + '.fasta.gz'
    compress_file(filtered_sequences, final_contig_file)

    write_md5(final_contig_file)



