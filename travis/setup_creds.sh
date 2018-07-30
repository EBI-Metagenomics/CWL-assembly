#!/usr/bin/env bash
file="$TRAVIS_BUILD_DIR/ena_api_creds.yml";
echo ${file};
touch ${file};
echo "API_URL: \"$ENA_API_URL\"" >> ${file};
echo "USER: \"$ENA_API_USERNAME\"" >> ${file};
echo "PASSWORD: \"$ENA_API_PASSWORD\"" >> ${file};

