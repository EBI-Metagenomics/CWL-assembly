import os
import random
import socket
from ruamel import yaml
import pytest

from src import download_manager

hash = str(random.getrandbits(128))

reference_socket = socket.socket


def download_and_validate_downloaded_files(tmpdir):
    log_dir = os.path.join(tmpdir, 'download_log.yml')
    raw_dir = os.path.join(tmpdir, 'raw')
    dlm = download_manager.DownloadManager(log_dir, raw_dir)
    urls = ("ftp.sra.ebi.ac.uk/vol1/ERA434/ERA434137/fastq/LD-Run2-17.fwd.fastq.gz",
            "ftp.sra.ebi.ac.uk/vol1/ERA434/ERA434137/fastq/LD-Run2-17.rev.fastq.gz")

    destinations = (os.path.join(raw_dir, 'LD-Run2-17.fwd.fastq.gz'),
                    os.path.join(raw_dir, 'LD-Run2-17.rev.fastq.gz')
                    )
    downloads = list(zip(urls, destinations))
    with dlm:
        dlm.download_urls(downloads)
    for dest in destinations:
        assert os.path.getsize(dest) > 0
    return dlm


def get_file_last_modified_times(dirname):
    files = [os.path.join(dirname, filename) for filename in os.listdir(dirname)]
    return {(filename, os.stat(filename).st_mtime) for filename in files}


class TestDownloadManager(object):
    @pytest.fixture(autouse=True)
    def reset_socket(self):
        yield
        socket.socket = reference_socket

    def test_download_manager_should_download_all_urls_2downloads(self, tmpdir):
        tmpdir = str(tmpdir)
        download_and_validate_downloaded_files(tmpdir)

    def test_download_manager_should_not_re_download_jobs(self, tmpdir):
        tmpdir = str(tmpdir)
        dlm = download_and_validate_downloaded_files(tmpdir)

        with dlm:
            assert 'LD-Run2-17.fwd.fastq.gz' in dlm.logged_downloads
            assert 'LD-Run2-17.rev.fastq.gz' in dlm.logged_downloads
        download_and_validate_downloaded_files(tmpdir)
        raw_dir = os.path.join(tmpdir, 'raw')
        modified_time = get_file_last_modified_times(raw_dir)
        download_and_validate_downloaded_files(tmpdir)

        modified_time_after_2nd_dl_attempt = get_file_last_modified_times(raw_dir)
        assert modified_time == modified_time_after_2nd_dl_attempt

    def test_should_store_successful_downloads_in_log(self, tmpdir):
        tmpdir = str(tmpdir)
        dlm = download_and_validate_downloaded_files(tmpdir)
        with open(dlm.logfile, 'r') as f:
            log_content = yaml.safe_load(f)
        # Check stored in logfile
        assert len(log_content) == 2
        assert 'LD-Run2-17.fwd.fastq.gz' in log_content
        assert 'LD-Run2-17.rev.fastq.gz' in log_content

        # Check logfile is correctly re-loaded at next pipeline kickoff
        log_dir = os.path.join(tmpdir, 'download_log.yml')
        raw_dir = os.path.join(tmpdir, 'raw')
        dlm2 = download_manager.DownloadManager(log_dir, raw_dir)
        with dlm2:
            assert 'LD-Run2-17.fwd.fastq.gz' in dlm2.logged_downloads
            assert 'LD-Run2-17.rev.fastq.gz' in dlm2.logged_downloads

    def test_process_download_should_return_true_on_succesful_dl(self, tmpdir):
        tmpdir = str(tmpdir)
        download_job = ("ftp.sra.ebi.ac.uk/vol1/ERA434/ERA434137/fastq/LD-Run2-17.fwd.fastq.gz",
                        os.path.join(tmpdir, 'LD-Run2-17.fwd.fastq.gz'))
        assert download_manager.process_download(download_job)

    def test_handling_download_error(self, tmpdir):
        def guard(*args, **kwargs):
            raise Exception("Internet access not available")

        socket.socket = guard
        tmpdir = str(tmpdir)
        with pytest.raises(download_manager.DownloadError):
            download_and_validate_downloaded_files(tmpdir)

    def test_process_download_should_return_false_on_dl_exception(self, tmpdir):
        def guard(*args, **kwargs):
            raise Exception("Internet access not available")

        socket.socket = guard
        tmpdir = str(tmpdir)
        download_job = ("ftp.sra.ebi.ac.uk/vol1/ERA434/ERA434137/fastq/LD-Run2-17.fwd.fastq.gz",
                        os.path.join(tmpdir, 'LD-Run2-17.fwd.fastq.gz'))
        assert not download_manager.process_download(download_job)
