import argparse
import logging
import json
import os

# Fix to allow developing using shared library, and also importing directly when using Docker container
from ena_portal_api import ena_handler
from mgnify_backlog import mgnify_handler as mh

logging.basicConfig(level=logging.INFO)


def parse_args():
    parser = argparse.ArgumentParser(description='Tool to retrieve metadata for runs in specified study')
    parser.add_argument('-s', '--study', help='Secondary study accession')
    parser.add_argument('-r', '--runs', help='Comma-seperated list of runs to assemble (omit to assemble all runs)')
    # parser.add_argument('-d', '--database', help='YML database config file, omit if not using database.',
    #                     default='prod', choices=['default', 'dev', 'prod'])
    # parser.add_argument('--no-db', action='store_true', help='Do not sync assembly jobs to mgnify database')
    # parser.add_argument('-a', '--assembler', help='Assembler to use with data',
    #                     choices=['metaspades', 'megahit', 'minia'], required=True)
    # parser.add_argument('-av', '--assembler-version', help='Version of assembler', required=True)
    # parser.add_argument('-iv', '--ignore-version', action='store_true',
    #                     help='Prepare runs even if they are already '
    #                          'assembled with another version of this program')
    # parser.add_argument('-f', '--force', action='store_true', help='Ignore execution status for assemblyJobs')
    return parser.parse_args()


def convert_file_locations(file_list):
    return list(map(lambda f: {"class": "File", "location": "file://" + os.path.join(os.getcwd(), os.path.basename(f))}, file_list))

def main():
    args = parse_args()

    ena = ena_handler.EnaApiHandler()
    runs = ena.get_study_runs(args.study, False)
    if args.runs:
        runs = list(filter(lambda r: r['run_accession'] in args.runs, runs))

    ena_handler.download_runs(runs)
    for run in runs:
        run['raw_reads'] = convert_file_locations(run['fastq_ftp'].split(';'))

    # if args.database and not args.no_db:
    #     db_handler = mh.MgnifyHandler(args.database)
    #     if not args.force:
    #         runs = db_handler.filter_active_runs(runs, args)
    #     ena_handler.download_runs(runs)
    #
    #     db_handler.store_entries(ena, runs, args)

    with open('cwl.output.json', 'w') as f:
        json.dump({"assembly_jobs": runs}, f, indent=4)


if __name__ == '__main__':
    main()
