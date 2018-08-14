import urllib
import multiprocessing
import hashlib
from ruamel import yaml
import os
import logging


class DownloadError(Exception):
    pass


class DownloadManager:
    def __init__(self, filepath, raw_dir):
        self.logfile = filepath
        self.raw_dir = raw_dir
        self.logged_downloads = None
        if not os.path.exists(raw_dir):
            os.makedirs(raw_dir)

    def __enter__(self):
        logging.debug('Reading download manager file {}'.format(self.logfile))
        if os.path.isfile(self.logfile):
            with open(self.logfile, 'r') as f:
                self.logged_downloads = yaml.safe_load(f) or {}
        else:
            self.logged_downloads = {}
        return self

    def __exit__(self, exception_type, exception_value, traceback):
        logging.debug('Writing download manager file {}'.format(self.logfile))
        with open(self.logfile, 'w+') as f:
            yaml.safe_dump(self.logged_downloads, f)

    def store_download(self, filename):
        self.logged_downloads[filename] = self.md5(filename)

    def is_already_downloaded(self, filename):
        download_is_cached = False
        if filename in self.logged_downloads:
            download_is_cached = self.md5(filename) == self.logged_downloads[filename]
        return download_is_cached

    def md5(self, filename):
        hash_md5 = hashlib.md5()
        filepath = self.get_file_path(filename)
        with open(filepath, "rb") as f:
            for chunk in iter(lambda: f.read(4096), b""):
                hash_md5.update(chunk)
        return hash_md5.hexdigest()

    def get_file_path(self, filename):
        return os.path.join(self.raw_dir, filename)

    def download_urls(self, downloads):
        downloads_required = [d for d in downloads if not self.is_already_downloaded(os.path.basename(d[1]))]
        logging.info('{} raw data downloads queued.'.format(len(downloads_required)))

        pool = multiprocessing.Pool(processes=4)
        results = pool.map(process_download, downloads_required)
        download_failed = False
        for filename, result in zip(downloads_required, results):
            if result:
                self.store_download(os.path.basename(filename[0]))
            else:
                download_failed = True
        if download_failed:
            raise DownloadError('Could not download all raw files for assembly.')


def process_download(download_job):
    url = download_job[0]
    dest = download_job[1]
    if 'ftp' in url and 'ftp://' not in url:
        url = 'ftp://' + url
    logging.info('\t\tDownloading ' + os.path.basename(dest))
    try:
        urllib.urlretrieve(url, dest)
    except Exception as e:
        logging.error(e)
        return False
    logging.info('\t\tFinished downloading ' + os.path.basename(dest))
    return True
