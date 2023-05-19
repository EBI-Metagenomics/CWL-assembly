from __future__ import print_function

import requests
import json
from ruamel import yaml

ENA_API_URL = "https://www.ebi.ac.uk/ena/portal/api/search"
def get_default_connection_headers():
    return {
        "headers": {
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "*/*"
        }
    }


def get_default_params():
    return {
        "result": "read_run",
        "dataPortal": "metagenome",
        "format": "json",
        "fields": "secondary_study_accession,run_accession,library_source,"
                  "library_strategy,library_layout,fastq_ftp",
        "limit": 10000
    }


def run_filter(d):
    return d['library_strategy'] != 'AMPLICON' and d['library_source'] == 'METAGENOMIC'


class EnaApiHandler:
    url = ENA_API_URL
    def __init__(self, config_file=None):
        config = []
        if config_file:
            with open(config_file, 'r') as f:
                config = yaml.safe_load(f)

            self.url = config['API_URL']
        if 'USER' in config and 'PASSWORD' in config:
            self.auth = (config['USER'], config['PASSWORD'])
        else:
            self.auth = None

    def post_request(self, data):
        if self.auth:
            response = requests.post(self.url, data=data, auth=self.auth, **get_default_connection_headers())
        else:
            response = requests.post(self.url, data=data, **get_default_connection_headers())
        return response

    def get_run_metadata(self, run_acc, filter_runs=True):
        data = get_default_params()
        data['query'] = "run_accession=\"{}\"".format(run_acc)
        response = self.post_request(data)
        if str(response.status_code)[0] != '2':
            raise ValueError('Could not retrieve run %s.', run_acc)
        run = json.loads(response.text)[0]
        if filter_runs and not run_filter(run):
            return None

        return run

    def get_study_runs(self, study_sec_acc, filter_runs=True):
        data = get_default_params()
        data['query'] = "secondary_study_accession=\"{}\"".format(study_sec_acc)

        response = self.post_request(data)
        if str(response.status_code)[0] != '2':
            raise ValueError('Could not retrieve runs for study %s.', study_sec_acc)

        runs = json.loads(response.text)
        if filter_runs:
            runs = list(filter(run_filter, runs))
        return runs