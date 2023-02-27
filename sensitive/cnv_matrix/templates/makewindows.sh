#!bash
module load bioinfo-tools BEDTools

cat !{variants} > all_variants.bed
bedtools sort -i all_variants.bed > all_variants_sorted.bed
bedtools merge -i all_variants_sorted.bed > merged.bed
bedtools makewindows -b merged.bed -w 200 > windows.bed