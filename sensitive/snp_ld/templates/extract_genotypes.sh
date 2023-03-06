ml bioinfo-tools plink2

plink2 \
  --recode A \
  --bfile ${genotypes} \
  --extract ${snp_ids} \
  --out `basename ${genotypes}` \
  --allow-extra-chr
