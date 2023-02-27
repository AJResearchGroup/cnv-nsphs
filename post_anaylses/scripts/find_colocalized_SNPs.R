#!RScript

library(readxl)
library(data.table)
library(stringr)

load_snps <- function(path) {
  snps <- read_excel(path, skip = 7L) |>
    as.data.table()
  setnames(snps, c("Chr...6", "Position*"), c("Chr", "Position"))
  snps[, .(Chr, Position, SNP, Beta, `P-value`, `Effective allele`, `Other Allele`)]
}

load_cnvs <- function(path) {
  cnvs <- read_excel(path) |>
  as.data.table()
matches <- cnvs$Coordinates |>
  str_remove_all(",") |>
  str_match("(\\d+):(\\d+)-(\\d+)")
cnvs$Chr <- matches[, 2] |> as.integer()
cnvs$Start <- matches[, 3] |> as.integer()
cnvs$End <- matches[, 4] |> as.integer()
}

find_colocalized_SNPs <- function(cnvs, significant_snps, flanks = 1e6L) {
    cnvs <- as.data.table(cnvs)
    significant_snps <- as.data.table(significant_snps)
    merged <- merge(cnvs, significant_snps, by=c("Chr", "Protein"), suffixes=c(".cnv", ".snp"))
    colocalized <- merged[Position >= Start - flanks][Position <= End + flanks]
    colocalized
}

args <- commandArgs(TRUE)

snp_path <- args[1]
cnv_path <- args[2]


significant_snps <- load_snps(snp_path)
cnvs <- load_cnvs(cnv_path)
colocalized <- find_colocalized_SNPs(cnvs, significant_snps)

# Write to STDOUT
fwrite(colocalized, "", sep="\t")