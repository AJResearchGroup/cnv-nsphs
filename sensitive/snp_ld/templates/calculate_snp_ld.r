#!Rscript
library(data.table)
library(foreach)

snps <- fread("!{snps}")
cnvs <- fread("!{cnvs}")
colocalizations <- fread("!{colocalizations}")

common_indivs <- intersect(snps$IID, colnames(cnvs))
common_indivs <- common_indivs[order(common_indivs)]

snps <- snps[IID %in% common_indivs]
setkey(snps, IID)

cnv_columns <- c("chr", "start", "end", common_indivs)
cnvs <- cnvs[, colnames(cnvs) %in% cnv_columns, with=FALSE]
setcolorder(cnvs, cnv_columns)

calculate_ld <- function(chromosome, cnv_start, rsID) {
    snp_column <- pmatch(rsID, colnames(snps))
    snp_alleles <- snps[[snp_column]] |> as.numeric()
    copy_numbers <- cnvs[chr == chromosome & start == cnv_start, -(1:3), with=FALSE] |> as.numeric()
    cor(snp_alleles, copy_numbers, method="spearman", use="complete.obs")^2
}

calc_all_ld <- Vectorize(calculate_ld)
colocalizations[,ld :=  calc_all_ld(Chr, Start, SNP)]

fwrite(colocalizations, "ld.txt", sep="\t")