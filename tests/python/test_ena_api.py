import pytest
from mock import patch
from src import ena_api


def get_acc(l):
    return [r['run_accession'] for r in l]


def mocked_requests_post(*args, **kwargs):
    class MockResponse:
        def __init__(self, json_data, status_code):
            self.json_data = json_data
            self.status_code = status_code

        def json(self):
            return self.json_data

    return MockResponse(None, 404)


class TestEnaHandler(object):
    @classmethod
    def setup_class(cls):
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

    @patch('src.ena_api.requests.post', side_effect=mocked_requests_post)
    def test_get_study_runs_raises_exception_on_http_error(self, ignored):
        with pytest.raises(ValueError):
            self.api.get_study_runs('ERP106645')

    def test_get_run_metadata_should_ignore_filter(self):
        assert self.api.get_run_metadata('ERR2281981', filter_runs=False)['run_accession'] == 'ERR2281981'

    def test_get_run_metadata_should_filter_amplicon(self):
        assert self.api.get_run_metadata('ERR2281981', filter_runs=True) is None

    def test_get_run_metadata_should_filter_genomic(self):
        assert self.api.get_run_metadata('ERR2359761', filter_runs=True) is None

    def test_get_run_metadata_raises_exception_on_invalid_accession(self):
        with pytest.raises(ValueError):
            self.api.get_run_metadata('IllegalAccession')

    @patch('src.ena_api.requests.post', side_effect=mocked_requests_post)
    def test_get_run_metadata_raises_exception_on_http_error(self, ignored):
        with pytest.raises(ValueError):
            self.api.get_run_metadata('ERR2359761')
