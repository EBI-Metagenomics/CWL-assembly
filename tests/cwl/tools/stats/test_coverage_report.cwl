- job: tests/cwl/tools/stats/job_descriptions/coverage-report.yml
  tool: cwl/stats/coverage-report.cwl
  output:
    logfile:
      checksum: sha1$f63a7f360a10051d37e77d7b770f64509f3c2072
      basename: out.json
      location: out.json
      class: File
      size: 436

