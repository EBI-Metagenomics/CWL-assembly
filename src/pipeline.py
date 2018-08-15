import argparse
import os.path

from util import Assembler
import ena_api
from assembly_job import AssemblyJob
from path_finder import PathFinder


def is_valid_file(parser, arg):
    if not os.path.exists(arg):
        parser.error("Input file %s does not exist!" % arg)
    else:
        return open(arg, 'r')  # return an open file handle


# def clean_input_row(row):
#     row = row.strip()
#     return row.split(' ')


# def get_job_runs(ena, job_accessions):
#     runs = []
#     for accession in job_accessions:
#         runs.extend(get_runs_from_accession(ena, accession))
#     return runs


# Used to define co-assembly: each row in input file lists all accessions which will be used in assembly
# def get_jobs_from_file(ena, args):
#     input_jobs = list(map(clean_input_row, args.file.readlines()))
#     args.file.close()
#     input_job_runs = list(map(lambda j: get_job_runs(ena, j), input_jobs))
#     return list(map(lambda accessions: AssemblyJob(ena, args, accessions), input_job_runs))


def get_runs_from_accession(ena, accession):
    if 'P' in accession:
        return ena.get_study_runs(accession, args.ignore_filter)
    elif 'R' in accession:
        accession = ena.get_run_metadata(accession, args.ignore_filter)
        return [accession] or []
    else:
        return []


def instantiate_jobs_from_args(path_finder, ena, args):
    input_job_runs = ena.get_study_runs(args.study, args.ignore_filter)
    if args.runs:
        runs = args.runs.split(',')
        input_job_runs = list(filter(lambda r: r['run_accession'] in runs, input_job_runs))
    return [AssemblyJob(path_finder, ena, args, run) for run in input_job_runs]


def parse_args():
    parser = argparse.ArgumentParser(description='Metagenomic assembly pipeline kickoff script')
    parser.add_argument('assembler', type=Assembler, choices=list(Assembler))
    parser.add_argument('--private', action='store_true')
    parser.add_argument('-m', '--memory', default=240, type=int, help='Memory allocation for pipeline (GB)')
    parser.add_argument('-d', '--dir', default='.', help='Root directory in which to run assemblies')
    parser.add_argument('-s', '--study', help='ENA project accession')
    parser.add_argument('-r', '--runs',
                        help='comma-seperated ENA run accessions to assemble (1 assembly per run) in specified project')
    parser.add_argument('--docker-cmd', dest='docker_cmd', choices=['docker', 'udocker'], default='docker',
                        help='Docker command to use in environemnt')

    # data_inputs = parser.add_mutually_exclusive_group()
    # single_projects = data_inputs.add_argument_group()
    # single_projects.add_argument('-s', '--study', help='ENA project accession')
    # single_projects.add_argument('-r', '--runs', help='comma-seperated ENA run accessions in specified project')

    # data_inputs.add_argument('-f', '--file', type=lambda x: is_valid_file(parser, x))

    parser.add_argument('-i', '--ignore_filter', action='store_true',
                        help='Ignore filtering of runs which are not metagenomic or are amplicon')
    return parser.parse_args()


def main(args):
    path_finder = PathFinder(args.dir, args.assembler.__str__())
    ena = ena_api.EnaApiHandler()
    assembly_jobs = instantiate_jobs_from_args(path_finder, ena, args)
    assembly_jobs = [job.launch_pipeline() for job in assembly_jobs]
    for job in assembly_jobs:
        print(
            'Study {} Run {} Return code: {}'.format(job.study_accession, job.run['run_accession'], job.process.wait()))
        if job.process.wait()!=0:
            print(job.toil_log_file)


if __name__ == '__main__':
    args = parse_args()
    main(args)
