from __future__ import print_function

import requests
from ruamel import yaml
import sys
import json
import os
import logging
from multiprocessing.pool import ThreadPool
import argparse

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


def fetch_url(entry):
    uri, path = entry
    if not os.path.exists(path):
        r = requests.get(uri, stream=True)
        if r.status_code == 200:
            with open(path, 'wb') as f:
                for chunk in r:
                    f.write(chunk)
    return path


def parse_args():
    parser = argparse.ArgumentParser(description='Tool to retrieve metadata for runs in specified study')
    parser.add_argument('study', help='Secondary study accession')
    parser.add_argument('-r', '--runs', help='Comma-seperated list of runs to assemble (omit to assemble all runs)')
    return parser.parse_args()


def main():
    args = parse_args()
    api = EnaApiHandler()
    try:
        logging.info('Fetching runs...')
        runs = api.get_study_runs(args.study)
        if args.runs:
            filter_runs = args.runs.split(',')
            runs = list(filter(lambda x: x['run_accession'] in filter_runs, runs))
    except IndexError:
        print('No study accession specified')
        sys.exit(1)

    downloads = []

    for d in runs:
        d['raw_reads'] = convert_file_locations(d['fastq_ftp'])
        d['read_count'] = int(d['read_count'])
        d['base_count'] = int(d['base_count'])
        del d['fastq_ftp']
        # TODO remove section if CWL support for ftp is fixed.
        for f in d['raw_reads']:
            url = f['location']
            dest = os.path.join(os.getcwd(), f['location'].split('/')[-1])
            downloads.append((f['location'], dest))
            f['location'] = 'file://' + dest

    results = ThreadPool(8).imap_unordered(fetch_url, downloads)
    for path in results:
        print(path)

    with open('cwl.output.json', 'w') as f:
        json.dump({"assembly_jobs": runs}, f, indent=4)


if __name__ == '__main__':
    main()
