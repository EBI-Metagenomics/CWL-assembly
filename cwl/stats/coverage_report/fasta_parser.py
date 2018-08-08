import re


class FastaStats:
    def __init__(self):
        self.contigs = []
        self.limit_stats = {}
        self.metadata = None
        self.coverage = None

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


def parse(file, min_contig_length):
    stat = FastaStats()
    largest_contig = 0
    lines = iter(file)
    current_length = None
    current_calculated_length = 0
    for line in lines:
        while '>' not in line:
            current_calculated_length += len(line.replace('\n', '').strip())
            try:
                line = next(lines)
            except StopIteration:
                break

        if '>' in line:
            # Finish contig
            if current_length and current_calculated_length:
                assert (current_length == current_calculated_length)
                if current_length >= min_contig_length:
                    stat.add_contig(current_length)
                if current_length > largest_contig:
                    largest_contig = current_length

            current_calculated_length = 0
            current_length, current_coverage = re.findall('NODE_\d+_length_(\d+)_cov_(\d+\.?\d*)+', line)[0]
            current_length = int(current_length)
    return {
        'Min length 1000 bp': stat.get_filtered_stats(1000),
        'Min length 10000 bp': stat.get_filtered_stats(10000),
        'Min length 50000 bp': stat.get_filtered_stats(50000),
        'num_contigs': len(stat.contigs),
        'total_assembled_pairs': stat.get_total_pairs(),
        'largest_contig': largest_contig,
        'n50': stat.get_n50(),
        'l50': stat.get_l50()
    }
