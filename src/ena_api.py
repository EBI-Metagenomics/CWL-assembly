from __future__ import print_function

import requests
import json
import logging
import yaml
import os

config_file = os.path.realpath(os.path.join(__file__, os.pardir, os.pardir, 'ena_api_creds.yml'))


def get_default_connection_headers():
    return {
        "headers": {
            "Content-Type": "application/x-www-form-urlencoded",
            "Accept": "*/*"
        }
    }


def run_filter(d):
    return d['library_strategy'] != 'AMPLICON' and d['library_source'] == 'METAGENOMIC'


def format_run(run):
    return {
        'accession': run['run_accession'],
        'layout': run['library_layout'],

    }


class EnaApiHandler:
    def __init__(self):
        with open(config_file, 'r') as f:
            config = yaml.load(f)

        self.url = config['API_URL']
        self.auth = (config['USER'], config['PASSWORD'])

    # def get_study_metadata(self, study_sec_acc):
    #     data = {
    #         "result": "study",
    #         "query": "secondary_study_accession=\"{}\"".format(study_sec_acc),
    #         "dataPortal": "metagenome",
    #         "format": "json",
    #         "fields": "study_accession,secondary_study_accession,study_title"
    #     }
    #     response = requests.post(self.url, data=data, auth=self.auth, **get_default_connection_headers())
    #     if str(response.status_code)[0] != '2':
    #         logging.error('Could not retrieve metadata for study')
    #         print(response)
    #         print(response.text)
    #         return {}
    #     return json.loads(response.text)[0]

    # def retrieve_run_metadata(self, run_prim_accession):
    #     data = {
    #         "result": "read_run",
    #         "query": "run_accession=\"{}\"".format(run_prim_accession),
    #         "dataPortal": "metagenome",
    #         "format": "json",
    #         "fields": "library_layout,library_strategy,library_source,read_count,base_count,instrument_platform,instrument_model,secondary_study_accession"
    #     }
    #     response = requests.post(self.url, data=data, auth=self.auth, **get_default_connection_headers())
    #     if str(response.status_code)[0] != '2':
    #         logging.error('Could not retrieve metadata for run')
    #         print(response.text)
    #         return {}
    #     return json.loads(response.text)[0]
    # 
    # def get_study_sec_accession(self, study_prim_accession):
    #     data = {
    #         "result": "study",
    #         "query": "study_accession=\"{}\"".format(study_prim_accession),
    #         "dataPortal": "metagenome",
    #         "format": "json",
    #         "fields": "study_accession,secondary_study_accession"
    #     }
    #     response = requests.post(self.url, data=data, auth=self.auth, **get_default_connection_headers())
    #     if str(response.status_code)[0] != '2':
    #         logging.error('Could not retrieve metadata for study')
    #         print(response)
    #         return {}
    #     return json.loads(response.text)[0]['secondary_study_accession']

    # def get_library_sources(study_sec_acc):
    #     data = {
    #         "result": "read_run",
    #         "query": "secondary_study_accession=\"{}\"".format(study_sec_acc),
    #         "dataPortal": "metagenome",
    #         "format": "json",
    #         "fields": "library_source,run_accession",
    #         "limit": 10000Changes in filter text should propagate to other facets

    #     }
    #     response = requests.post(url, **get_default_connection_headers(), data=data, auth=auth)
    #     if str(response.status_code)[0] != '2':
    #         logging.error('Could not retrieve library source for runs.')
    #         print(response)
    #         return {}
    #     return {d['run_accession']: d['library_source'] for d in json.loads(response.text)}

    def get_run_metadata(self, run_acc, filter_runs=True):
        data = {
            "result": "read_run",
            "query": "run_accession=\"{}\"".format(run_acc),
            "dataPortal": "metagenome",
            "format": "json",
            "fields": "secondary_study_accession,run_accession,library_source,"
                      "library_strategy,library_layout,submitted_ftp",
            "limit": 10000
        }
        response = requests.post(self.url, data=data, auth=self.auth, **get_default_connection_headers())
        if str(response.status_code)[0] != '2':
            raise ValueError('Could not retrieve run %s.', run_acc)
        run = json.loads(response.text)[0]
        if filter_runs and not run_filter(run):
            return None

        return run

    def get_study_runs(self, study_sec_acc, filter_runs=True):
        data = {
            "result": "read_run",
            "query": "secondary_study_accession=\"{}\"".format(study_sec_acc),
            "dataPortal": "metagenome",
            "format": "json",
            "fields": "secondary_study_accession,run_accession,library_source,"
                      "library_strategy,library_layout,submitted_ftp",
            "limit": 10000
        }
        response = requests.post(self.url, data=data, auth=self.auth, **get_default_connection_headers())
        if str(response.status_code)[0] != '2':
            raise ValueError('Could not retrieve runs for study %s.', study_sec_acc)

        runs = json.loads(response.text)
        if filter_runs:
            num_runs = len(runs)
            runs = list(filter(run_filter, runs))
            num_filtered_runs = num_runs - len(runs)
            logging.info('Filtered out %s runs.', num_filtered_runs)
        return runs


if __name__ == '__main__':
    ena = EnaApiHandler()
    print(ena.get_study_runs('ERP001736'))
