import argparse
import json
import sys
import re


class FastaStats:
    def __init__(self, fasta_file, assembler):
        self.contigs = []
        self.limit_stats = {}
        self.metadata = None
        self.coverage = None
        self.largest_contig = None
        self.fasta_file = fasta_file
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
                self.contigs.append(current_length)
                if current_length > largest_contig:
                    largest_contig = current_length

    def gen_report(self):
        return {
            'limited_1000': self.get_filtered_stats(1000),
            'limited_10000': self.get_filtered_stats(10000),
            'limited_50000': self.get_filtered_stats(50000),
            'num_contigs': len(self.contigs),
            'total_assembled_pairs': self.get_total_pairs(),
            'largest_contig': self.get_largest_contig(),
            'n50': self.get_n50(),
            'l50': self.get_l50()
        }

    def get_filtered_stats(self, limit):
        contigs = list(filter(lambda x: x >= limit, self.contigs))
        return [len(contigs), sum(contigs)]

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


def calc_coverage(coverage_file, base_count):
    with coverage_file as f:
        assembled_pairs = 0
        assembly_length = 0
        lines = iter(f)
        try:
            _ = next(lines)
        except StopIteration:
            raise ValueError('Coverage file {} is invalid.'.format(coverage_file.name))
        for l in f:
            line = l.split()
            length = float(line[1])
            read_depth = float(line[2])
            assembled_pairs += (length * read_depth)
            assembly_length += length
    if assembly_length == 0:
        return assembled_pairs / base_count, float(0), assembly_length
    else:
        return assembled_pairs / base_count, assembled_pairs / assembly_length, assembly_length


def parse_assembly_log(logfile, assembler):
    spades_version_re = re.compile('SPAdes version: (.+)')
    megahit_version_re = re.compile('MEGAHIT v(\d+\.\d+\.\d+)')

    with open(logfile, 'r') as f:
        line = next(f, None)
        while line:
            if megahit_version_re.search(line) and assembler == 'megahit':
                version = megahit_version_re.findall(line)[0]
                return version
            elif "System information" in line:
                version = spades_version_re.findall(next(f))[0]
                return version
            line = next(f, '')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Script to calculate coverage from coverage.tab file and output report")
    parser.add_argument('--sequences', type=argparse.FileType('r'), help='.fasta file')
    parser.add_argument('--coverage_file', type=argparse.FileType('r'), help='Coverage.tab file')
    parser.add_argument('--assembler', choices=['metaspades', 'spades', 'megahit'],
                        help='Assembler used to generate sequence.')
    parser.add_argument('--logfile', help='assembly log file')
    parser.add_argument('--base_count', help='Sum of base count for all input files', nargs='+')
    args = parser.parse_args()

    base_counts = []
    read_counts = []
    for x in args.base_count:
        with open(x, 'r') as in_count:
            rcount = in_count.readline().rstrip()
            bcount = in_count.readline().rstrip()
            base_counts.append(int(rcount))
            read_counts.append(int(bcount))
    total_base_count = sum(base_counts)
    total_read_count = sum(read_counts)
    if total_base_count <= 0:
        raise ValueError('Base count ({}) cannot be <= 0.'.format(total_base_count))
    coverage, coverage_depth, assembly_length = None, None, None
    if args.coverage_file:
        coverage, coverage_depth, assembly_length = calc_coverage(args.coverage_file, total_base_count)
    fstats = FastaStats(args.sequences, args.assembler)
    args.sequences.close()
    report = fstats.gen_report()

    #counts
    report['input_read_count'] = total_read_count
    report['input_base_count'] = total_base_count
    # coverage stats
    if args.coverage_file:
        report['coverage'] = coverage
        report['coverage_depth'] = coverage_depth
        report['assembly_length'] = assembly_length

    #assembler info
    report['assembler_name'] = args.assembler
    report['assembler_version'] = parse_assembly_log(args.logfile, args.assembler)
    with open('assembly_stats.json', 'w+') as output:
        output.write(json.dumps(report, indent=4, sort_keys=True))
    sys.exit(0)
