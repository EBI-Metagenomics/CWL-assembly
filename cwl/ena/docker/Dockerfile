FROM python:3.6-slim

LABEL maintainer="Miguel Boland <mdb@ebi.ac.uk>"

##############################################################
# Dockerfile Version:
# Software:
# Software Version:     1.0.0
# Description:
##############################################################
COPY ./*.py /

RUN apt-get update && apt-get install -y git default-libmysqlclient-dev gcc
RUN pip install -U git+https://github.com/EBI-Metagenomics/ebi-metagenomics-libs.git --process-dependency-links

CMD ["python", "/pre_assembly.py"]

