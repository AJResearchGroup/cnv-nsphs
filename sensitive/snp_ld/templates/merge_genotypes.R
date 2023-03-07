#!Rscript

library(data.table)

outer_join <- function(x,y) {
    merge(x, y, all=TRUE)
}

list.files(pattern="geno") |>
  lapply(fread) |>
  Reduce(f=outer_join) |>
  fwrite("combined.raw", sep="\t")