#!/usr/bin/env bash
echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin

docker push mgnify/cwl-assembly-readfq:latest

docker push mgnify/cwl-assembly-stats-report:latest

docker push mgnify/cwl-assembly-fasta-trimming:latest