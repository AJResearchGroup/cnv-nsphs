#!Rscript
library(data.table)
library(stringr)
library(magrittr)

# args <- commandArgs(TRUE)
variant_file <- "!{variants}"
results_file <- basename(variant_file) %>% str_replace(".txt", "_qc.bed")

variants <- fread(variant_file)
if (nrow(variants) == 0){ # If the original is empty, the result is empty, too
  write.table(data.table(), results_file)
} else {
  names(variants) <- c("type", "coordinates", "size", "rd_norm", "e1", "e2", "e3", "e4", "q0")
  passing_qc <- variants[q0 >= 0][q0 <= 0.5][size >= 1000][e1 <= 0.00005]
  coordinates <- str_split_fixed(passing_qc$coordinates, ":|-", n=3) %>% as.data.table()
  names(coordinates) <- c("#chr", "start", "stop")
  result <- cbind(coordinates, passing_qc[, .(cn = rd_norm * 2, e1 = e1, e2 = e2, q0 = q0, size = size)])

  write.table(result, results_file, sep="\t", quote=FALSE, row.names=FALSE)
}
