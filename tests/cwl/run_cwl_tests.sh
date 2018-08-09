#!/usr/bin/env bash
source $TRAVIS_BUILD_DIR/toil-3.16.0-dev/bin/activate;
echo "Testing megahit container";
cwltest --basedir cwl_test_dir --test tests/cwl/tools/assemblers/test_megahit.yml --tool cwltool --verbose &&\
echo "Testing metaspades container" &&\
cwltest --basedir cwl_test_dir --test tests/cwl/tools/assemblers/test_metaspades.yml --tool cwltool --verbose &&\
echo "Testing spades container" &&\
cwltest --basedir cwl_test_dir --test tests/cwl/tools/assemblers/test_spades.yml --tool cwltool --verbose &&\

echo "Testing stats tools" &&\
cwltest --basedir cwl_test_dir --test tests/cwl/tools/stats/readfq.cwl --tool cwltool --verbose &&\
cwltest --basedir cwl_test_dir --test tests/cwl/tools/stats/test_fasta_trimming.yml --tool cwltool --verbose &&\
cwltest --basedir cwl_test_dir --test tests/cwl/tools/stats/test_trim_fasta.yml --tool cwltool --verbose &&\

echo "Testing stats workflow" &&\
cwltest --basedir cwl_test_dir --test tests/cwl/workflows/test_stats.cwl --tool cwltool --verbose

