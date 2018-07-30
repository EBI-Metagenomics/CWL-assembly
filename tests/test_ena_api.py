from src import ena_api
from unittest import TestCase
import pytest


def get_acc(l):
    return [r['run_accession'] for r in l]


class TestEnaHandler(TestCase):
    @classmethod
    def setUpClass(cls):
        cls.api = ena_api.EnaApiHandler()

    def test_get_study_runs_should_filter_amplicons(self):
        # Test with metagenomic data
        assert self.api.get_study_runs('ERP106645', filter_runs=True) == []

    def test_get_study_runs_should_not_filter_metagenomic_runs(self):
        assert set(get_acc(self.api.get_study_runs('ERP009740', filter_runs=True))) == {'ERR776677', 'ERR776678'}

    def test_get_study_runs_should_ignore_filter(self):
        assert set(get_acc(self.api.get_study_runs('ERP106645', filter_runs=False))) == {'ERR2281981', 'ERR2281982',
                                                                                         'ERR2281983', 'ERR2281984',
                                                                                         'ERR2281985', 'ERR2281986'}

    def test_get_study_runs_raises_exception_on_invalid_accession(self):
        with pytest.raises(ValueError):
            self.api.get_study_runs('IllegalAccession')

    def test_get_run_metadata_should_ignore_filter(self):
        assert self.api.get_run_metadata('ERR2281981', filter_runs=False)['run_accession'] == 'ERR2281981'

    def test_get_run_metadata_should_filter_amplicon(self):
        assert self.api.get_run_metadata('ERR2281981', filter_runs=True) is None

    def test_get_run_metadata_should_filter_genomic(self):
        assert self.api.get_run_metadata('ERR2359761', filter_runs=True) is None

    def test_get_run_metadata_raises_exception_on_invalid_accession(self):
        with pytest.raises(ValueError):
            self.api.get_run_metadata('IllegalAccession')

