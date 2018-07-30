FROM python:3.4-slim
MAINTAINER Miguel Boland <mdb@ebi.ac.uk>

##############################################################
# Dockerfile Version:   18.06.0-ce
# Software:             metaspades
# Software Version:     3.12.0
# Software Website:     http://cab.spbu.ru/software/meta-spades/
# Description:          Assembly of metagenomic data via the METASpades assembler
##############################################################

WORKDIR /metaspades
ENV VERSION=3.12.0

ADD . /metaspades
ADD "http://cab.spbu.ru/files/release${VERSION}/SPAdes-${VERSION}-Linux.tar.gz" .
RUN tar -xzf SPAdes-${VERSION}-Linux.tar.gz \
    && mv SPAdes-${VERSION}-Linux metaspades

CMD ["python", "metaspades/bin/metaspades.py"]