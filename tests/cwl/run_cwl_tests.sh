#!/usr/bin/env bash
source $TRAVIS_BUILD_DIR/toil-3.16.0-dev/bin/activate;
cwltest --basedir cwl_test_dir --test tests/cwl/tools/assemblers/test_megahit.yml --tool cwltool --verbose && \
cwltest --basedir cwl_test_dir --test tests/cwl/tools/assemblers/test_metaspades.yml --tool cwltool --verbose && \
cwltest --basedir cwl_test_dir --test tests/cwl/workflows/test_stats.cwl --tool cwltool --verbose

