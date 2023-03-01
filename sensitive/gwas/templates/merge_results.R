#!Rscript

library(data.table)

gwas <-list.files(pattern="glm") |>
  lapply(fread) |>
  rbindlist()

saveRDS(gwas, "gwas.RDS")

p_threshold <- .05 / nrow(gwas)
gwas[p < p_threshold] |>
  saveRDS("significant_cnvs.RDS")