#!/usr/bin/env bash
virtualenv toil-3.16.0-dev
source toil-3.16.0-dev/bin/activate
pip install -U pip setuptools
pip install wheel
cd toil-3.16.0-dev

pip install -r requirements.txt
pip install -r requirements-test
curl https://raw.githubusercontent.com/indigo-dc/udocker/devel/udocker.py > ../bin/udocker
chmod 775 ../bin/udocker
udocker install
cd ..
wget https://nodejs.org/dist/v8.11.1/node-v8.11.1-linux-x64.tar.xz && tar -xJf node-v8.11.1-linux-x64.tar.xz
export PATH="$PWD/node-v8.11.1-linux-x64/bin/:$PATH"



curl https://raw.githubusercontent.com/indigo-dc/udocker/master/udocker.py > udocker;
chmod u+rx ./udocker;
 ./udocker install;
 ./udocker pull metabat/metabat:latest;
cd common-workflow-language
#TMP=$PWD ./run_test.sh RUNNER=toil-cwl-runner EXTRA="--batchSystem LSF --logDebug --logFile ${PWD}/log --disableCaching --user-space-docker-cmd=udocker" -j8
