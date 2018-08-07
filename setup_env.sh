#!/usr/bin/env bash
virtualenv toil-3.16.0-dev
source toil-3.16.0-dev/bin/activate
pip install -U pip setuptools
pip install -r requirements.txt
pip install -r requirements-test.txt

cd toil-3.16.0-dev

curl https://raw.githubusercontent.com/indigo-dc/udocker/devel/udocker.py > bin/udocker
chmod 775 bin/udocker
udocker install
wget https://nodejs.org/dist/v8.11.1/node-v8.11.1-linux-x64.tar.xz && tar -xJf node-v8.11.1-linux-x64.tar.xz
export PATH="$PWD/node-v8.11.1-linux-x64/bin/:$PATH"
echo "PATH=$PWD/node-v8.11.1-linux-x64/bin/:\$PATH" >> bin/activate
