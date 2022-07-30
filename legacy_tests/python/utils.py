import os
import shutil

FIXTURE_DIR = os.path.join(os.path.dirname(__file__), os.pardir, 'fixtures')


def write_empty_file(filename):
    open(filename, 'a').close()
    return filename


def copy_fixture(src, dest):
    shutil.copy(os.path.join(FIXTURE_DIR, src), dest)
    return dest


def remove_file(filename):
    if os.path.exists(filename):
        shutil.rmtree(filename)
