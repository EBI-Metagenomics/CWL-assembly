from unittest import TestCase
import os
import shutil
import pytest
import json
import mimetypes
import gzip

from tests.python.utils import write_empty_file, copy_fixture

from cwl.stats.fasta_trimming.trim_fasta import parse_args, write_md5, md5, trim_fasta_file, compress_file
from cwl.stats.stats_report.gen_stats_report import FastaStats


def trim_and_validate_against_trim(original_file, output_file, min_contig_length, assembler):
    trim_fasta_file(original_file, min_contig_length, output_file, assembler)
    with open(original_file) as f:
        original_fstats = FastaStats(f, 0, assembler)
    original_report = original_fstats.gen_report()

    with open(output_file) as f:
        trimmed_fstats = FastaStats(f, 0, assembler)
    trimmed_report = trimmed_fstats.gen_report()

    assert trimmed_report['num_contigs'] < original_report['num_contigs']
    assert trimmed_report['total_assembled_pairs'] < original_report['total_assembled_pairs']
    remaining_contigs = list(filter(lambda r: r >= min_contig_length, original_fstats.contigs))
    assert trimmed_fstats.contigs == remaining_contigs


class TestFastaTrimmer(object):
    def test_trim_fasta_file_unsupported_assembler(self):
        with pytest.raises(ValueError):
            trim_fasta_file('contigs.fasta', 500, 'output.fasta', 'minia')

    def test_trim_metaspades_assembler(self, tmpdir):
        tmpdir = str(tmpdir)
        assembler = 'metaspades'
        min_contig_length = 200
        fasta_file = copy_fixture('ERP0102/ERP010229/ERR8665/ERR866589/metaspades/001/contigs.fasta',
                                  tmpdir + '/contigs.fasta')
        output_file = tmpdir + 'output.fasta'
        trim_and_validate_against_trim(fasta_file, output_file, min_contig_length, assembler)

    def test_trim_megahit_assembler(self, tmpdir):
        tmpdir = str(tmpdir)
        assembler = 'megahit'
        min_contig_length = 400
        fasta_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/final.contigs.fa',
                                  tmpdir + '/contigs.fasta')
        output_file = tmpdir + 'output.fasta'
        trim_and_validate_against_trim(fasta_file, output_file, min_contig_length, assembler)

    def test_compress_file_should_be_smaller(self, tmpdir):
        tmpdir = str(tmpdir)
        fasta_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/final.contigs.fa',
                                  tmpdir + '/contigs.fasta')
        out_file = fasta_file + '.gzip'
        compress_file(fasta_file, out_file)
        assert os.path.exists(out_file)
        assert os.stat(fasta_file).st_size > os.stat(out_file).st_size

    def test_compress_file_should_be_gzip(self, tmpdir):
        tmpdir = str(tmpdir)
        fasta_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/final.contigs.fa',
                                  tmpdir + '/contigs.fasta')
        out_file = fasta_file + '.gzip'
        compress_file(fasta_file, out_file)
        out_file_content = gzip.open(out_file, 'rb').read()
        assert open(fasta_file, 'rb').read() == out_file_content

    def test_compress_file_should_make_output_dir(self, tmpdir):
        tmpdir = str(tmpdir)
        fasta_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/final.contigs.fa',
                                  tmpdir + '/contigs.fasta')
        out_file = os.path.join(os.path.dirname(fasta_file), 'extra_dir', os.path.basename(fasta_file) + '.gzip')
        compress_file(fasta_file, out_file)
        assert os.path.exists(out_file)

    def test_write_md5(self, tmpdir):
        tmpdir = str(tmpdir)
        fasta_file = copy_fixture('SRP0741/SRP074153/SRR6257/SRR6257420/megahit/001/final.contigs.fa',
                                  tmpdir + '/contigs.fasta')
        write_md5(fasta_file)
        with open(fasta_file + '.md5') as f:
            md5 = f.read()
        assert md5 == 'dc94b51a736f6a43e146f1c1133d7aab'
