import argparse
import os.path
import sys
import logging

from util import Assembler
import ena_api
from assembly_job import AssemblyJob, CoAssemblyJob
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


def instantiate_coassembly_jobs_from_args(path_finder, ena, args):
    studies = args.studies.split(',')
    input_job_runs = [run for study_acc in studies for run in ena.get_study_runs(study_acc, args.ignore_filter)]
    if args.runs:
        runs = args.runs.split(',')
        input_job_runs = list(filter(lambda r: r['run_accession'] in runs, input_job_runs))
    return [CoAssemblyJob(path_finder, ena, args, input_job_runs)]


def instantiate_jobs_from_args(path_finder, ena, args):
    input_job_runs = ena.get_study_runs(args.study, args.ignore_filter)
    if args.runs:
        runs = args.runs.split(',')
        input_job_runs = list(filter(lambda r: r['run_accession'] in runs, input_job_runs))
    return [AssemblyJob(path_finder, ena, args, run) for run in input_job_runs]


def parse_args(args):
    parser = argparse.ArgumentParser(description='Metagenomic assembly pipeline kickoff script')
    parser.add_argument('--batch_system', choices=['lsf'])
    parser.add_argument('assembler', type=Assembler, choices=list(Assembler))
    parser.add_argument('--private', action='store_true')
    parser.add_argument('-m', '--memory', default=240, type=int, help='Memory allocation for assembly (GB).')
    parser.add_argument('-c', '--cores', default=16, type=int, help='Number of cores / threads for assembly.')
    parser.add_argument('-d', '--dir', default='.', help='Root directory in which to run assemblies')
    parser.add_argument('--docker-cmd', dest='docker_cmd', choices=['docker', 'udocker'], default='docker',
                        help='Docker command to use in environemnt')
    parser.add_argument('-ena', '--ena-credentials-file', help='Yaml file containing USERNAME and PASSWORD.')

    single_study = parser.add_argument_group('Normal assembly')
    single_study.add_argument('-s', '--study', help='ENA study accession')

    co_assembly = parser.add_argument_group('Co-assembly')
    co_assembly.add_argument('-ss', '--studies', help='Comma-seperated ENA study accessions for co-assembly')

    run_filers = parser.add_mutually_exclusive_group()
    run_filers.add_argument('--all', help='Co-assemble all runs in specified studies')
    run_filers.add_argument('-r', '--runs',
                            help='Comma-seperated ENA run accessions to assemble in specified study(ies)')

    parser.add_argument('-i', '--ignore_filter', action='store_true',
                        help='Ignore filtering of runs which are not metagenomic or are amplicon')
    return parser.parse_args(args)


def main(args=None):
    if not args:
        args = parse_args(sys.argv[1:])
    if not (args.study or args.studies):
        logging.error('No studies specified, please provide -s SRP###### or -ss SRP######[,SRP######]')
        sys.exit(1)
    if not (args.runs or args.all):
        logging.error('No runs specified, please provide -r ERR######[,ERR#######] or --all.')
        sys.exit(1)

    path_finder = PathFinder(args.dir, args.assembler.__str__())
    ena = ena_api.EnaApiHandler(config_file=args.ena_credentials_file)
    if args.studies:
        assembly_jobs = instantiate_coassembly_jobs_from_args(path_finder, ena, args)
    else:
        assembly_jobs = instantiate_jobs_from_args(path_finder, ena, args)
    assembly_jobs = [job.launch_pipeline() for job in assembly_jobs]
    all_jobs_succesful = True
    for job in assembly_jobs:
        print(
            'Study {} Run {} Return code: {}'.format(job.study_accession, job.assembly_name, job.process.wait()))
        if job.process.wait() != 0:
            print(job.toil_log_file)
            all_jobs_succesful = False

    sys.exit(0 if all_jobs_succesful else 1)


if __name__ == '__main__':
    args = parse_args(sys.argv[1:])
    main(args)

