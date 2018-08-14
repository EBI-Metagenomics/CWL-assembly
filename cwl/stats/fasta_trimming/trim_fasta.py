import re
import argparse
import gzip
import os
import shutil
import hashlib
import sys


def trim_fasta_file(source_file, threshold, output_file, assembler):
    if assembler in ['spades', 'metaspades']:
        contig_regex = 'NODE_\d+_length_(\d+)_cov_*'
    elif assembler == 'megahit':
        contig_regex = 'k.+flag=.+multi=.+len=(\d+)'
    else:
        raise ValueError('Assembler ' + assembler + ' is not supported')
    with open(output_file, 'w+') as out:
        with open(source_file, 'r') as inp:
            store_line = False
            for line in inp:
                if '>' in line:
                    current_length = re.findall(contig_regex, line)[0]
                    store_line = (int(current_length) >= threshold)
                if store_line:
                    out.write(line)
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


def parse_args(args):
    parser = argparse.ArgumentParser(description='Remove contigs of length < min_contig_length from a fasta file.')
    parser.add_argument("sequences", help='Path to fasta file to trim')
    parser.add_argument("min_contig_length", help='Minimum contig length, set to 0 for no trimming', type=int)
    parser.add_argument("contig_filename", help='Filename (without ANY extension) to give to contig files')
    parser.add_argument('assembler', choices=['metaspades', 'spades', 'megahit'],
                        help='Assembler used to generate sequence.')
    return parser.parse_args(args)


def main(args):
    if not os.path.exists(args.sequences):
        raise EnvironmentError('Fasta file does not exist: {}'.format(args.sequences))

    final_contig_name = args.contig_filename

    if args.min_contig_length > 0:
        trim_fasta_file(args.sequences, args.min_contig_length, final_contig_name + '.fasta', args.assembler)
    else:
        shutil.copy(args.sequences, final_contig_name + '.fasta')

    compressed_filename = final_contig_name + '.fasta.gz'
    compress_file(args.sequences, compressed_filename)

    write_md5(compressed_filename)


if __name__ == '__main__':
    args = parse_args(sys.argv[1:])
    main(args)
