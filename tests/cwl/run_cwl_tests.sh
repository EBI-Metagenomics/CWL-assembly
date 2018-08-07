#!/usr/bin/env bash
source $TRAVIS_BUILD_DIR/toil-3.16.0-dev/bin/activate;
cwltest --basedir cwl_test_dir --test tests/cwl/test_megahit.yml --tool cwltool && \
cwltest --basedir cwl_test_dir --test tests/cwl/test_metaspades.yml --tool cwltool