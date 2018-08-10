import urllib.request
import multiprocessing
import shutil


def process_download(download_job):
    url = download_job[0]
    dest = download_job[1]
    if 'ftp' in url:
        url = 'ftp://' + url
    print(f'\t\tDownloading {dest}')
    with urllib.request.urlopen(url) as response, open(dest, 'wb') as out_file:
        shutil.copyfileobj(response, out_file)
    print(f'\t\tFinished downloading {dest}')


def download_urls(urls):
    pool = multiprocessing.Pool(processes=4)  # how much parallelism?
    pool.map(process_download, urls)
