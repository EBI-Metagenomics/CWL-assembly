from setuptools import setup, find_packages
from setuptools.command.install import install

import subprocess
import os
import sys

version = "0.1.1"

_base = os.path.dirname(os.path.abspath(__file__))
_requirements = os.path.join(_base, 'requirements.txt')
_requirements_test = os.path.join(_base, 'requirements-test.txt')
_env_activate = os.path.join(_base, 'venv', 'bin', 'activate')

install_requirements = []
with open(_requirements) as f:
    install_requirements = f.read().splitlines()

test_requirements = []
if "test" in sys.argv:
    with open(_requirements_test) as f:
        test_requirements = f.read().splitlines()


class InstallCommand(install):
    def run(self):
        #£ret = subprocess.Popen(['bash', './setup_env.sh']).wait()
        #if ret:
        #    raise EnvironmentError('Failed to install non-python dependencies.')
        install.run(self)

setup(
    name="MGnify CWL assembly pipeline",
    version=version,
    packages=find_packages(exclude=['ez_setup']),
    install_requires=install_requirements,
    include_package_data=True,
    setup_requires=['pytest-runner'],
    tests_require=test_requirements,
    test_suite="tests",
    cmdclass={'install': InstallCommand},
    entry_points={
        'console_scripts': [
            'assembly_cli = src.pipeline:main'
        ]
    }
)
