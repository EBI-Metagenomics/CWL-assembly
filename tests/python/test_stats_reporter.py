import pytest
import json

from cwl.stats.stats_report import gen_stats_report
from tests.python.utils import write_empty_file, copy_fixture


class TestStatsReporter(object):
    def test_coverage_report_fixture_empty_coverage_file(self, tmpdir):
        tmpdir = str(tmpdir)
        coverage_file = write_empty_file(tmpdir + '/tmp.tab')
        contig_file = write_empty_file(tmpdir + 'contigs.fasta')
        output_file = write_empty_file(tmpdir + 'output.json')
        with pytest.raises(ValueError) as exc:
            args = gen_stats_report.parse_args(
                ['106000', contig_file, coverage_file, output_file, '500', 'metaspades'])
            gen_stats_report.calc_coverage(args)
        # Assert error comes from coverage file message, not fasta parsing error
        assert 'Coverage file' in str(exc)

    def test_coverage_report_fixture_empty_fasta_file(self, tmpdir):
        tmpdir = str(tmpdir)
        coverage_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/coverage.tab',
                                     tmpdir + 'tmp.tab')
        contig_file = write_empty_file(tmpdir + 'contigs.fasta')
        output_file = write_empty_file(tmpdir + 'output.json')

        open(coverage_file, 'a').close()
        args = gen_stats_report.parse_args(
            ['106000', contig_file, coverage_file, output_file, '500', 'metaspades'])
        coverage = gen_stats_report.calc_coverage(args)
        assert coverage == 14.2

    def test_main_metaspades(self, tmpdir):
        tmpdir = str(tmpdir)
        contig_file = copy_fixture('ERP0102/ERP010229/ERR8665/ERR866589/metaspades/001/contigs.fasta',
                                   tmpdir + 'contigs.fasta')
        coverage_file = copy_fixture('ERP0102/ERP010229/ERR8665/ERR866589/metaspades/001/coverage.tab',
                                     tmpdir + 'coverage.tab')

        output_file = write_empty_file(tmpdir + 'output.json')
        base_count = 106000
        args = gen_stats_report.parse_args(
            [str(base_count), contig_file, coverage_file, output_file, '0', 'metaspades'])
        try:
            gen_stats_report.main(args)
        except SystemExit:
            pass

        expected_report = {
            'Base count': base_count,
            'Coverage': 0.01,
            'Min length 1000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
            'Min length 10000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
            'Min length 50000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
            'num_contigs': 5,
            'total_assembled_pairs': 262 + 245 + 116 + 87 + 60,
            'largest_contig': 262,
            'n50': 2,
            'l50': 4
        }
        with open(output_file) as output:
            report = json.load(output)
        assert expected_report == report

    def test_main_megahit(self, tmpdir):
        tmpdir = str(tmpdir)
        contig_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/final.contigs.fa',
                                   tmpdir + 'contigs.fasta')
        coverage_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/coverage.tab',
                                     tmpdir + 'coverage.tab')

        output_file = write_empty_file(tmpdir + 'output.json')
        base_count = 106000
        args = gen_stats_report.parse_args([str(base_count), contig_file, coverage_file, output_file, '0', 'megahit'])
        try:
            gen_stats_report.main(args)
        except SystemExit:
            pass

        expected_report = {
            'Base count': base_count,
            'Coverage': 14.2,
            'Min length 1000 bp': {'num_contigs': 1, 'total_base_pairs': 2473},
            'Min length 10000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
            'Min length 50000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
            'num_contigs': 22,
            'total_assembled_pairs': 11716,
            'largest_contig': 2473,
            'n50': 9,
            'l50': 14
        }
        with open(output_file) as output:
            report = json.load(output)
        assert expected_report == report

    def test_raises_error_on_invalid_basecount(self, tmpdir):
        tmpdir = str(tmpdir)
        contig_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/final.contigs.fa',
                                   tmpdir + 'contigs.fasta')
        coverage_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/coverage.tab',
                                     tmpdir + 'coverage.tab')
        output_file = write_empty_file(tmpdir + 'output.json')
        with pytest.raises(ValueError) as exc:
            args = gen_stats_report.parse_args(['0', contig_file, coverage_file, output_file, '0', 'metaspades'])
            gen_stats_report.main(args)
        # Assert error comes from coverage file message, not fasta parsing error
        assert 'Base count (0) cannot be <= 0.' in str(exc)


class TestFastaStats(object):
    def test_supported_assemblers(self):
        supported = ['metaspades', 'spades', 'megahit']
        for assembler in supported:
            fstats = gen_stats_report.FastaStats('contigs.fasta', 500, assembler)
            assert fstats.assembler == assembler

    def test_unsupported_assemblers(self):
        unsupported = ['minia', 'invalid_assembler']
        for assembler in unsupported:
            with pytest.raises(ValueError):
                gen_stats_report.FastaStats('contigs.fasta', 500, assembler)

    def test_stats_empty_fasta(self, tmpdir):
        tmpdir = str(tmpdir)
        contig_file = write_empty_file(tmpdir + 'contigs.fasta')
        with open(contig_file) as f:
            fstats = gen_stats_report.FastaStats(f, 500, 'metaspades')
            fstats.parse_file()
            assert fstats.get_largest_contig() == 0
            assert fstats.get_n50() == 0
            assert fstats.get_l50() == 0
            assert fstats.get_total_pairs() == 0
            assert fstats.get_filtered_stats(100) == {'num_contigs': 0, 'total_base_pairs': 0}

    def test_stats_valid_metaspades_fasta_no_contig_filtering(self, tmpdir):
        tmpdir = str(tmpdir)
        contig_file = copy_fixture('ERP0102/ERP010229/ERR8665/ERR866589/metaspades/001/contigs.fasta',
                                   tmpdir + 'contigs.fasta')
        with open(contig_file) as f:
            fstats = gen_stats_report.FastaStats(f, 0, 'metaspades')
            fstats.parse_file()
            expected_report = {
                'Min length 1000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
                'Min length 10000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
                'Min length 50000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
                'num_contigs': 5,
                'total_assembled_pairs': 262 + 245 + 116 + 87 + 60,
                'largest_contig': 262,
                'n50': 2,
                'l50': 4
            }
            assert fstats.get_largest_contig() == expected_report['largest_contig']
            assert fstats.get_n50() == expected_report['n50']
            assert fstats.get_l50() == expected_report['l50']
            assert fstats.get_total_pairs() == expected_report['total_assembled_pairs']
            assert fstats.get_filtered_stats(100) == {'num_contigs': 3, 'total_base_pairs': 262 + 245 + 116}
            assert fstats.gen_report() == expected_report

    def test_stats_valid_metaspades_fasta_with_contig_filtering(self, tmpdir):
        tmpdir = str(tmpdir)
        contig_file = copy_fixture('ERP0102/ERP010229/ERR8665/ERR866589/metaspades/001/contigs.fasta',
                                   tmpdir + 'contigs.fasta')
        with open(contig_file) as f:
            fstats = gen_stats_report.FastaStats(f, 100, 'metaspades')
            fstats.parse_file()
            expected_report = {
                'Min length 1000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
                'Min length 10000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
                'Min length 50000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
                'num_contigs': 3,
                'total_assembled_pairs': 262 + 245 + 116,
                'largest_contig': 262,
                'n50': 2,
                'l50': 2
            }
            assert fstats.get_largest_contig() == expected_report['largest_contig']
            assert fstats.get_n50() == expected_report['n50']
            assert fstats.get_l50() == expected_report['l50']
            assert fstats.get_total_pairs() == expected_report['total_assembled_pairs']
            assert fstats.get_filtered_stats(100) == {'num_contigs': 3, 'total_base_pairs': 262 + 245 + 116}
            assert fstats.gen_report() == expected_report

    def test_stats_valid_megahit_fasta_no_contig_filtering(self, tmpdir):
        tmpdir = str(tmpdir)
        contig_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/final.contigs.fa',
                                   tmpdir + 'contigs.fasta')
        with open(contig_file) as f:
            fstats = gen_stats_report.FastaStats(f, 0, 'megahit')
            fstats.parse_file()
            contig_lengths = 11716
            expected_report = {
                'Min length 1000 bp': {'num_contigs': 1, 'total_base_pairs': 2473},
                'Min length 10000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
                'Min length 50000 bp': {'num_contigs': 0, 'total_base_pairs': 0},
                'num_contigs': 22,
                'total_assembled_pairs': contig_lengths,
                'largest_contig': 2473,
                'n50': 9,
                'l50': 14
            }
            assert fstats.get_largest_contig() == expected_report['largest_contig']
            assert fstats.get_n50() == expected_report['n50']
            assert fstats.get_l50() == expected_report['l50']
            assert fstats.get_total_pairs() == expected_report['total_assembled_pairs']
            assert fstats.get_filtered_stats(700) == {'num_contigs': 3, 'total_base_pairs': 2473 + 767 + 730}
            assert fstats.gen_report() == expected_report

    def test_stats_valid_megahit_fasta_with_contig_filtering(self, tmpdir):
        tmpdir = str(tmpdir)

        contig_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/final.contigs.fa',
                                   tmpdir + 'contigs.fasta')
        with open(contig_file) as f:
            fstats = gen_stats_report.FastaStats(f, 700, 'megahit')
            fstats.parse_file()
            contig_lengths = 2473 + 767 + 730
            expected_report = {
                'Min length 1000 bp': {
                    'num_contigs': 1,
                    'total_base_pairs': 2473
                },
                'Min length 10000 bp': {
                    'num_contigs': 0,
                    'total_base_pairs': 0
                },
                'Min length 50000 bp': {
                    'num_contigs': 0,
                    'total_base_pairs': 0
                },
                'num_contigs': 3,
                'total_assembled_pairs': contig_lengths,
                'largest_contig': 2473,
                'n50': 1,
                'l50': 3
            }
            assert fstats.get_largest_contig() == expected_report['largest_contig']
            assert fstats.get_n50() == expected_report['n50']
            assert fstats.get_l50() == expected_report['l50']
            assert fstats.get_total_pairs(), expected_report['total_assembled_pairs']
            assert fstats.get_filtered_stats(2000) == {'num_contigs': 1, 'total_base_pairs': 2473}
            assert fstats.gen_report() == expected_report
