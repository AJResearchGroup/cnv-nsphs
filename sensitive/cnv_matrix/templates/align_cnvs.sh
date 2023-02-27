
module load bioinfo-tools BEDTools

variant_file="!{variants}"
out_file="$(basename $variant_file .bed)_200bp.bed"

# Columns 4, 5 and 6 of bedtools intersect are the coordinates of the original CNV calls.
# We are not interested in them.
# The first sort sorts the BED by position and q0 value
# The second sort discards all rows with the same position except for the first one it encounters
# This is the row with the lowest q0 value.
bedtools intersect -wao -f 0.5 -a "!{windows}" -b "$variant_file" \
  | awk -v sample_size="!{sample_size}" '
    BEGIN {
      OFS = "\t";
      q_threshold = 0.05/sample_size
    }
    ($7 == "."){
      copy_number = 2
    }
    ($7 != "." && $8 <= q_threshold){
      copy_number = $7
    }
    ($7 != "." && $8 > q_threshold){
      copy_number = "NA"
    }
    {
      #     chr, start, end, copy number, remaining columns
      print  $1,    $2,  $3, copy_number, $8, $9, $10, $11, $12
    }' \
  | sort -n -k1,1 -k2,2 -k3,3 -k5,5 \
  | sort -un -k1,1 -k2,2 -k3,3 \
  > $out_file