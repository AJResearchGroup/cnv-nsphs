#!/bin/bash
module load ROOT/6.06.08 bioinfo-tools CNVnator/0.3.3
chrom=$(seq 1 22)
cnvnator -root !{root} -partition "!{bin_size}" -chrom $chrom
