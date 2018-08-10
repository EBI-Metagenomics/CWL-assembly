import os
import random

from src import download

hash = str(random.getrandbits(128))


class TestDownloadLib(object):

    def test_download_urls_should_download_all_urls_2downloads(self, tmpdir):
        tmpdir = str(tmpdir)
        urls = ("ftp.sra.ebi.ac.uk/vol1/ERA434/ERA434137/fastq/LD-Run2-17.fwd.fastq.gz",
                "ftp.sra.ebi.ac.uk/vol1/ERA434/ERA434137/fastq/LD-Run2-17.rev.fastq.gz")

        destinations = (os.path.join(tmpdir, 'file1.fastq.gz'),
                        os.path.join(tmpdir, 'file2.fastq.gz')
                        )
        downloads = list(zip(urls, destinations))
        download.download_urls(downloads)
        for dest in destinations:
            assert os.path.getsize(dest) > 0
            os.remove(dest)

    def test_process_download_should_download_job(self, tmpdir):
        tmpdir = str(tmpdir)
        downloads = ("ftp.sra.ebi.ac.uk/vol1/ERA434/ERA434137/fastq/LD-Run2-17.fwd.fastq.gz",
                     os.path.join(tmpdir, 'file4.fastq.gz'))

        download.process_download(downloads)
        dest = downloads[1]
        assert os.path.getsize(dest) > 0
        os.remove(dest)
