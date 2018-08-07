# This Python script requires Biopython 1.51 or later
from Bio.SeqIO.QualityIO import FastqGeneralIterator
import itertools

# Setup variables (could parse command line args instead)
file_f = "ERP0102/ERP010229/raw/ERR866589_1.fastq"
file_r = "ERP0102/ERP010229/raw/ERR866589_2.fastq"
file_out = "ERP0102/ERP010229/raw/ERR866589_merged.fastq"
handle = open(file_out, "w")
count = 0
f_iter = FastqGeneralIterator(open(file_f, "rU"))
r_iter = FastqGeneralIterator(open(file_r, "rU"))
for (f_id, f_seq, f_q), (r_id, r_seq, r_q) in itertools.izip(f_iter, r_iter):
    count += 2
    # Write out both reads with "/1" and "/2" suffix on ID
    handle.write("@%s/1n%sn+n%sn@%s/2n%sn+n%sn"
                 % (f_id, f_seq, f_q, r_id, r_seq, r_q))
handle.close()
print
"%i records written to %s" % (count, file_out)
