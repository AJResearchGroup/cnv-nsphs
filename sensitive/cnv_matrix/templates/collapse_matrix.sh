inBed="!{cnv_matrix}"
Lines=$(wc -l < $inBed) #! $echo "$Lines" and $echo $Lines give different values
# The population matirx in read into 4 field: Chromosome, StartPosition, EndPosition, Population_genotype(1031 genotype, read as a string)
PreChrom=1
PreStart=0
PreEnd=0
PreGenotype=""
counter=0
while read Chrom Start End Genotype;
do
  counter=$((counter+1))
  if [ "$counter" = $Lines ] # If read to the last line, [ "$counter" = "$Lines "] doesn't work, Lines=$(wc -l < $inBed) causes error when "$Lines"
  then
    #echo "Last line"
    if [ "$Chrom" = "$PreChrom" ] && [ "$Start" = "$PreEnd" ] && [ "$Genotype" = "$PreGenotype" ]
    then
      PreEnd="$End"
      echo -e "$PreChrom\t$PreStart\t$PreEnd\t$PreGenotype"
    else
      echo -e "$PreChrom\t$PreStart\t$PreEnd\t$PreGenotype"
      echo -e "$Chrom\t$Start\t$End\t$Genotype"
    fi
  elif  [ "$Chrom" = "$PreChrom" ] && [ "$Start" = "$PreEnd" ] && [ "$Genotype" = "$PreGenotype" ] # if the current window has the same genotype as the previous window:
  then
    PreEnd="$End"
  else
    if [ "$counter" != 1 ]
    then
      echo -e "$PreChrom\t$PreStart\t$PreEnd\t$PreGenotype"
    fi
    PreChrom="$Chrom"
    PreStart="$Start"
    PreEnd="$End"
    PreGenotype="$Genotype"
  fi
done < $inBed > cnv_matrix_collapsed.txt