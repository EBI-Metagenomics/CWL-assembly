#include <zlib.h>
#include <stdio.h>
#include "kseq.h"

/* Built from https://github.com/billzt/readfq */
/* Modified by Miguel Boland (mdb@ebi.ac.uk) to handle multiple input files */

// reference: http://lh3lh3.users.sourceforge.net/parsefastq.shtml

// Tao Zhu 2015-08-30

// STEP 1: declare the type of file handler and the read() function
KSEQ_INIT(gzFile, gzread)

int main(int argc, char *argv[])
{
    gzFile fp;
    if (argc == 1) {
        fprintf(stderr, "Usage: %s <in.seq>\n", argv[0]);
        return 1;
    }
    long int totalSlen = 0;
    for (int i = 1; i< argc; i++){
        kseq_t *seq;
        int l;
        long int slen = 0;
        fp = gzopen(argv[i], "r"); // STEP 2: open the file handler
        seq = kseq_init(fp); // STEP 3: initialize seq
        while ((l = kseq_read(seq)) >= 0) { // STEP 4: read sequence
            slen += seq->seq.l;
        }
        totalSlen +=slen;
           kseq_destroy(seq); // STEP 5: destroy seq
        gzclose(fp); // STEP 6: close the file handler
    }
    // Total Num Bases:
    printf("%ld", totalSlen);
    return 0;
}