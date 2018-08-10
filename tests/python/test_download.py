# import os
# import random
# from unittest import TestCase
#
# from src import download
#
# hash = str(random.getrandbits(128))
# test_dir = os.path.join(os.pardir, 'tmp' + hash)
#
#
# class TestDownloadLib(TestCase):
#     @classmethod
#     def setup_class(cls):
#         os.makedirs(test_dir, exist_ok=True)
#
#     def test_download_urls_should_download_all_urls_2downloads(self):
#         urls = ("ftp.sra.ebi.ac.uk/vol1/ERA434/ERA434137/fastq/LD-Run2-17.fwd.fastq.gz",
#                 "ftp.sra.ebi.ac.uk/vol1/ERA434/ERA434137/fastq/LD-Run2-17.rev.fastq.gz")
#
#         destinations = (os.path.join(test_dir, 'file1.fastq.gz'),
#                         os.path.join(test_dir, 'file2.fastq.gz')
#                         )
#         downloads = list(zip(urls, destinations))
#         download.download_urls(downloads)
#         for dest in destinations:
#             assert os.path.getsize(dest) > 0
#             os.remove(dest)
#
#     def test_process_download_should_download_job(self):
#         downloads = ("ftp.sra.ebi.ac.uk/vol1/ERA434/ERA434137/fastq/LD-Run2-17.fwd.fastq.gz",
#                      os.path.join(test_dir, 'file4.fastq.gz'))
#
#         download.process_download(downloads)
#         dest = downloads[1]
#         assert os.path.getsize(dest) > 0
#         os.remove(dest)
#
#     @classmethod
#     def tareDownClass(cls):
#         os.rmdir(test_dir)
