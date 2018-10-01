from __future__ import print_function

import requests
from ruamel import yaml
import sys
import json
import os
import subprocess

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
                  "library_strategy,library_layout,fastq_ftp,base_count,read_count",
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

        self.url = "https://www.ebi.ac.uk/ena/portal/api/search"
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
        data['fields'] = "run_accession,fastq_ftp,library_strategy,library_source,library_layout,read_count,base_count"
        response = self.post_request(data)
        if str(response.status_code)[0] != '2':
            raise ValueError('Could not retrieve runs for study %s.', study_sec_acc)

        runs = json.loads(response.text)
        if filter_runs:
            runs = list(filter(run_filter, runs))
        return runs


def convert_file_locations(file_list):
    return list(map(lambda f: {"class": "File", "location": "http://" + f}, file_list.split(';')))


FNULL = open(os.devnull, 'w')


def download_file(path):
    p = subprocess.Popen(['wget', path], stdout=FNULL, stderr=subprocess.STDOUT)
    p.wait()


if __name__ == '__main__':
    api = EnaApiHandler()
    runs = api.get_study_runs(sys.argv[1])
    runs = list(filter(lambda r: r['run_accession'] in ['SRR6257420'], runs))
    for d in runs[0:2]:
        d['raw_reads'] = convert_file_locations(d['fastq_ftp'])
        d['read_count'] = long(d['read_count'])
        d['base_count'] = long(d['base_count'])
        del d['fastq_ftp']
        # TODO remove section if needed
        for f in d['raw_reads']:
            url = f['location']
            dest = f['location'].split('/')[-1]
            download_file(f['location'])
            f['location'] = 'file://' + os.path.join(os.getcwd(), dest)
    with open('cwl.output.json', 'w') as f:
        json.dump({"assembly_jobs": runs[0:2]}, f, indent=4)
