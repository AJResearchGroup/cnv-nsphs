#!Rscript

library(data.table)
library(foreach)

gwas_results <- "!{gwas_results}"
cnv_matrix <- "!{cnv_matrix}"

calculate_ld <- function(chromosome, lead_start, cnv_starts, genotypes) {
  lead_cnv <- genotypes[chr == chromosome & start == lead_start]
  lead_cns <- lead_cnv[, -(1:3), with = FALSE] |> as.numeric()
  foreach(cnv_start = cnv_starts) %do% {
    cnv2 <- genotypes[chr == chromosome & start == cnv_start]
    cnv2_cns <- cnv2[, -(1:3), with = FALSE] |> as.numeric()
    cor(lead_cns, cnv2_cns, method = "spearman", use = "complete.obs")^2
  }
}

clump <- function(
    gwas,
    cnvs,
    merge_threshold = 0.8,
    indenpendence_threshold = .1) {
  foreach(current_chr = unique(gwas$chr), .combine = "rbind") %:%
    foreach(current_marker = unique(gwas$marker), .combine = "rbind") %do% {
      # Create an empty data table with the same columns as gwas
      blocks <- gwas[FALSE]
      hits <- gwas[chr == current_chr & marker == current_marker]
      while (nrow(hits) > 0) {
        lead <- hits[which.min(p)] # Lead is CNV with lowest p value
        ld <- calculate_ld(current_chr, lead$start, hits$start, cnvs)
        strong_ld <- which(ld > merge_threshold)
        independent <- which(ld < indenpendence_threshold)
        # Make a copy so we don't change the underlying data table
        block <- copy(lead)
        # Block spans from first cnv in LD to last CNV in strong LD
        block$start <- hits[min(strong_ld), start]
        block$end <- hits[max(strong_ld), end]
        blocks <- rbind(blocks, block)
        # Remove all CNVs in at least weak LD with the block
        hits <- hits[independent]
      }
      # return all found blocks
      blocks
    }
}

clump(fread(gwas_results), fread(cnv_matrix)) |>
  fwrite("clumps.txt")
