#!Rscript

library(data.table)

list.files(pattern="glm") |>
  lapply(fread) |>
  rbindlist() |>
  saveRDS("gwas.RDS")