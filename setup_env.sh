#!/bin/bash
#virtualenv venv
#source venv/bin/activate
#pip install -U pip setuptools
#pip install -r requirements.txt
#pip install -r requirements-test.txt
#

INSTALL_DIR="$(dirname $(dirname $(which python)))";
CURL_VERSION="7.61.0";

echo "Checking docker installation..."
if ! [ -x "$(command -v docker)" ]; then
    echo "Docker not found, installing udocker in ${INSTALL_DIR}";
    curl https://raw.githubusercontent.com/indigo-dc/udocker/devel/udocker.py > ${INSTALL_DIR}/bin/udocker;
    chmod 775 ${INSTALL_DIR}/bin/udocker;
    udocker install;
    echo "Installed udocker in venv";

    echo "Installing latest curl to bypass HTTP 400 error in udocker pull";
    wget -O ${INSTALL_DIR}/curl-${CURL_VERSION}.tar.gz https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz;
    tar -xzf ${INSTALL_DIR}/curl-${CURL_VERSION}.tar.gz
    cd ${INSTALL_DIR}/curl-${CURL_VERSION};
    make;
    mv ${INSTALL_DIR}/curl-${CURL_VERSION}/src/curl ${INSTALL_DIR}/venv/bin/;
    cd ${INSTALL_DIR};
    echo "Installed curl v7.61 in venv";
else
    echo "Found docker installation.";
fi

echo "Checking for node installation...";
if ! [ -x "$(command -v node)" ]; then
    echo "Node not found, installing in ${INSTALL_DIR}";
    curl https://nodejs.org/dist/v8.11.1/node-v8.11.1-linux-x64.tar.xz > ${INSTALL_DIR}/node-v8.11.1-linux-x64.tar.xz;
    tar -xzf ${INSTALL_DIR}/node-v8.11.1-linux-x64.tar.xz -C ${INSTALL_DIR};
    export PATH="${INSTALL_DIR}/node-v8.11.1-linux-x64/bin/:$PATH";
    echo "PATH=${INSTALL_DIR}/node-v8.11.1-linux-x64/bin/:\$PATH" >> ${INSTALL_DIR}/bin/activate
    echo "Installed node in venv"
else
    echo "Found node installation."
fi
