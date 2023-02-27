#!/bin/bash
# load the ROOT library
module load ROOT/6.06.08 bioinfo-tools CNVnator/0.3.3

bin_sizes=(70 85 100 150 200 250)
chrom=$(seq 1 22)
root_file="!{root}"
sample=$(basename "$root_file" .root)

for bin_size in "${bin_sizes[@]}"
do
  cnvnator -root "$root_file" -his "$bin_size" -chrom $chrom -d "!{reference}" 1>&2
  # CNVnator outputs a log message from which we have to extract the mean RD and its SD.
  echo "$(cnvnator -root "$root_file" -stat "$bin_size" -chrom $chrom | perl -ne 'print "$1 $2\n" if /^Average RD per bin \(1-22\) is (\d+\.\d+) \+- (\d+\.\d+) \(after GC correction\)/') $bin_size" >> ${sample}_stats.txt
done

best_size=$(awk '
  BEGIN {
    max_ratio=5;
    best_size=-1;
  }
  {
    ratio = $1 / $2;
    if (ratio >= 4 && ratio <= max_ratio) {
      best_size=$3;
      max_ratio=ratio;
    }
  }
  END {printf "%d", best_size}' ${sample}_stats.txt)

# Partitioning
cnvnator -root $root_file -partition "$best_size" -chrom $chrom

# Calling
variants_file="$(basename $root_file .root)_variants.txt"
cnvnator -root $root_file -call "$best_size" > $variants_file

