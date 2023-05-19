import os
import shutil
import urllib

from ruamel import yaml
import pytest

from src import download_manager

current_dir = os.path.dirname(__file__)
fixtures_dir = os.path.join(current_dir, os.pardir, 'fixtures')


def fake_valid_urlretrieve(url, dest):
    url_srcs = {
        "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR866/ERR866589/ERR866589_1.fastq.gz":
            os.path.join(fixtures_dir, 'ERP0102/ERP010229/raw/ERR866589_1.fastq.gz'),
        "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR866/ERR866589/ERR866589_2.fastq.gz":
            os.path.join(fixtures_dir, 'ERP0102/ERP010229/raw/ERR866589_2.fastq.gz')
    }
    src = url_srcs[url]
    shutil.copy(src, dest)


def fake_invalid_urlretrieve(url, dest):
    raise EnvironmentError('Blocked mock download. (arguments {}, {})'.format(url, dest))


def download_and_validate_downloaded_files(tmpdir):
    log_dir = os.path.join(tmpdir, 'download_log.yml')
    raw_dir = os.path.join(tmpdir, 'raw')
    dlm = download_manager.DownloadManager(log_dir, raw_dir)
    urls = ("ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR866/ERR866589/ERR866589_1.fastq.gz",
            "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR866/ERR866589/ERR866589_2.fastq.gz")

    destinations = [os.path.join(raw_dir, os.path.basename(url)) for url in urls]
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
        download_manager.urllib.urlretrieve = urllib.urlretrieve

    def test_download_manager_should_download_all_urls_2downloads(self, tmpdir):
        download_manager.urllib.urlretrieve = fake_valid_urlretrieve
        tmpdir = str(tmpdir)
        download_and_validate_downloaded_files(tmpdir)

    def test_download_manager_should_not_re_download_jobs(self, tmpdir):
        download_manager.urllib.urlretrieve = fake_valid_urlretrieve
        tmpdir = str(tmpdir)
        dlm = download_and_validate_downloaded_files(tmpdir)

        with dlm:
            assert 'ERR866589_1.fastq.gz' in dlm.logged_downloads
            assert 'ERR866589_2.fastq.gz' in dlm.logged_downloads
        download_and_validate_downloaded_files(tmpdir)
        raw_dir = os.path.join(tmpdir, 'raw')
        modified_time = get_file_last_modified_times(raw_dir)
        download_and_validate_downloaded_files(tmpdir)

        modified_time_after_2nd_dl_attempt = get_file_last_modified_times(raw_dir)
        assert modified_time == modified_time_after_2nd_dl_attempt

    def test_should_store_successful_downloads_in_log(self, tmpdir):
        download_manager.urllib.urlretrieve = fake_valid_urlretrieve
        tmpdir = str(tmpdir)
        dlm = download_and_validate_downloaded_files(tmpdir)
        with open(dlm.logfile, 'r') as f:
            log_content = yaml.safe_load(f)
        # Check stored in logfile
        assert len(log_content) == 2
        assert 'ERR866589_1.fastq.gz' in log_content
        assert 'ERR866589_2.fastq.gz' in log_content

        # Check logfile is correctly re-loaded at next pipeline kickoff
        log_dir = os.path.join(tmpdir, 'download_log.yml')
        raw_dir = os.path.join(tmpdir, 'raw')
        dlm2 = download_manager.DownloadManager(log_dir, raw_dir)
        with dlm2:
            assert 'ERR866589_1.fastq.gz' in dlm2.logged_downloads
            assert 'ERR866589_2.fastq.gz' in dlm2.logged_downloads

    def test_process_download_should_return_true_on_succesful_dl(self, tmpdir):
        download_manager.urllib.urlretrieve = fake_valid_urlretrieve
        tmpdir = str(tmpdir)
        download_job = ("ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR866/ERR866589/ERR866589_1.fastq.gz",
                        os.path.join(tmpdir, 'LD-Run2-17.fwd.fastq.gz'))
        assert download_manager.process_download(download_job)

    def test_handling_download_error(self, tmpdir):
        download_manager.urllib.urlretrieve = fake_invalid_urlretrieve
        tmpdir = str(tmpdir)
        urls = ("ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR866/ERR866589/ERR866589_1.fastq.gz",
                "ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR866/ERR866589/ERR866589_2.fastq.gz")
        downloads = [(url, '') for url in urls]
        log_dir = os.path.join(tmpdir, 'download_log.yml')
        raw_dir = os.path.join(tmpdir, 'raw')
        dlm = download_manager.DownloadManager(log_dir, raw_dir)

        with pytest.raises(download_manager.DownloadError), dlm:
            dlm.download_urls(downloads)

    def test_process_download_should_return_false_on_dl_exception(self, tmpdir):
        download_manager.urllib.urlretrieve = fake_invalid_urlretrieve
        tmpdir = str(tmpdir)
        download_job = ("ftp://ftp.sra.ebi.ac.uk/vol1/fastq/ERR866/ERR866589/ERR866589_1.fastq.gz",
                        os.path.join(tmpdir, 'ERR866589_1.fastq.gz'))
        log_dir = os.path.join(tmpdir, 'download_log.yml')
        raw_dir = os.path.join(tmpdir, 'raw')
        dlm = download_manager.DownloadManager(log_dir, raw_dir)

        with dlm:
            assert not download_manager.process_download(download_job)