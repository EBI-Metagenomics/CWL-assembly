import argparse
import json
import sys
import fasta_parser


def parse_args():
    parser = argparse.ArgumentParser(
        description="Script to calculate coverage from coverage.tab file and output report")
    parser.add_argument('base_count', type=int, help='Sum of base count for all input files')
    parser.add_argument('sequences', type=argparse.FileType('r'), help='.fasta file')
    parser.add_argument('coverage_file', type=argparse.FileType('r'), help='Coverage.tab file')
    parser.add_argument('output', help='JSON Output file')
    parser.add_argument('min_contig_length', type=int, help='Minimum contig length')
    return parser.parse_args()


def calc_coverage(args):
    with args.coverage_file as f:
        assembled_pairs = 0
        lines = iter(f)
        _ = next(lines)
        for l in f:
            line = l.split()
            length = float(line[1])
            read_depth = float(line[2])
            assembled_pairs += (length * read_depth)
    return round(assembled_pairs / args.base_count, 2)


def main(args):
    coverage = calc_coverage(args)
    stats = fasta_parser.parse(args.sequences, args.min_contig_length)
    stats['Base count'] = args.base_count
    stats['Coverage'] = coverage
    with open(args.output, 'w+') as output:
        output.write(json.dumps(stats, indent=4, sort_keys=True))
    sys.exit(0)


if __name__ == '__main__':
    args = parse_args()
    main(args)
