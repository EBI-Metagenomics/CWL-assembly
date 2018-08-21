FROM alpine:3.8

LABEL maintainer="Miguel Boland <mdb@ebi.ac.uk>"

COPY . /
RUN apk add zlib-dev --no-cache gcc musl-dev; \
    gcc -o kseq_fastq_base /kseq_fastq_base.c -lz
ENV LIBRARY_PATH=/lib:/usr/lib

CMD ["/bin/bash", "/kseq_fastq_base"]

# docker run --volume $PWD:/data readfq:latest /kseq_fastq_base /data/ERR866589_1.fastq.gz