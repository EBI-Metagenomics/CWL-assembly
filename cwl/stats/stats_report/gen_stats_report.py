import argparse
import json
import sys
import re


def parse_args(args):
    parser = argparse.ArgumentParser(
        description="Script to calculate coverage from coverage.tab file and output report")
    parser.add_argument('base_count', type=int, help='Sum of base count for all input files')
    parser.add_argument('sequences', type=argparse.FileType('r'), help='.fasta file')
    parser.add_argument('coverage_file', type=argparse.FileType('r'), help='Coverage.tab file')
    parser.add_argument('output', help='JSON Output file')
    parser.add_argument('min_contig_length', type=int, help='Minimum contig length')
    parser.add_argument('assembler', choices=['metaspades', 'spades', 'megahit'],
                        help='Assembler used to generate sequence.')
    return parser.parse_args(args)


class FastaStats:
    def __init__(self, fasta_file, min_contig_length, assembler):
        self.contigs = []
        self.limit_stats = {}
        self.metadata = None
        self.coverage = None
        self.largest_contig = None
        self.fasta_file = fasta_file
        self.min_contig_length = min_contig_length
        if assembler in ['spades', 'metaspades']:
            self.contig_regex = 'NODE_\d+_length_(\d+)_cov_*'
        elif assembler == 'megahit':
            self.contig_regex = 'k.+flag=.+multi=.+len=(\d+)'
        else:
            raise ValueError('Assembler ' + assembler + ' is not supported')
        self.assembler = assembler

        self.parse_file()

    def parse_file(self):
        largest_contig = 0
        lines = iter(self.fasta_file)
        for line in lines:
            if '>' in line:
                current_length = int(re.findall(self.contig_regex, line)[0])
                if current_length >= self.min_contig_length:
                    self.add_contig(current_length)
                if current_length > largest_contig:
                    largest_contig = current_length

    def gen_report(self):
        return {
            'Min length 1000 bp': self.get_filtered_stats(1000),
            'Min length 10000 bp': self.get_filtered_stats(10000),
            'Min length 50000 bp': self.get_filtered_stats(50000),
            'num_contigs': len(self.contigs),
            'total_assembled_pairs': self.get_total_pairs(),
            'largest_contig': self.get_largest_contig(),
            'n50': self.get_n50(),
            'l50': self.get_l50()
        }

    def add_contig(self, length):
        self.contigs.append(length)

    def get_filtered_stats(self, limit):
        contigs = list(filter(lambda x: x >= limit, self.contigs))
        return {
            'num_contigs': len(contigs),
            'total_base_pairs': sum(contigs)
        }

    def get_n50(self):
        if len(self.contigs) == 0:
            return 0

        half_contigs = sum(self.contigs) / 2
        total_top = 0
        n50 = 0
        while total_top <= half_contigs:
            total_top += self.contigs[n50]
            n50 += 1
        return n50

    def get_l50(self):
        if len(self.contigs) == 0:
            return 0

        half_contigs = sum(self.contigs) / 2
        num_contigs = len(self.contigs)
        total_bot = 0
        l50 = 0
        while total_bot <= half_contigs:
            total_bot += self.contigs[num_contigs - l50 - 1]
            l50 += 1
        return l50

    def get_largest_contig(self):
        if len(self.contigs) == 0:
            return 0
        return max(self.contigs)

    def get_total_pairs(self):
        return sum(self.contigs)


def calc_coverage(args):
    with args.coverage_file as f:
        assembled_pairs = 0
        lines = iter(f)
        try:
            _ = next(lines)
        except StopIteration:
            raise ValueError('Coverage file {} is invalid.'.format(args.coverage_file.name))
        for l in f:
            line = l.split()
            length = float(line[1])
            read_depth = float(line[2])
            assembled_pairs += (length * read_depth)
    return round(assembled_pairs / args.base_count, 2)


def main(args):
    if args.base_count <= 0:
        raise ValueError('Base count ({}) cannot be <= 0.'.format(args.base_count))
    coverage = calc_coverage(args)
    fstats = FastaStats(args.sequences, args.min_contig_length, args.assembler)
    args.sequences.close()
    report = fstats.gen_report()
    report['Base count'] = args.base_count
    report['Coverage'] = coverage
    with open(args.output, 'w+') as output:
        output.write(json.dumps(report, indent=4, sort_keys=True))
    sys.exit(0)


if __name__ == '__main__':
    args = parse_args(sys.argv[1:])
    main(args)
