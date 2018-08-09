FROM amd64/gcc:latest

COPY * /
RUN gcc -lz -o kseq_fastq_base /kseq_fastq_base.c

CMD ["/bin/bash", "/kseq_fastq_base"]

# docker run --volume $PWD:/data readfq:latest /kseq_fastq_base /data/ERR866589_1.fastq.gz