#!Rscript
library(data.table)
library(stringr)
library(magrittr)

is_not_empty <- function(dt){
  nrow(dt) > 0
}

filenames <- "!{bed_files}" %>%
  str_split(" ") %>%
  unlist()

key <- fread("!{translation_key}", header=TRUE, fill=TRUE)
# Some rows have double tabs after the filename. Account for those by shifting columns left
key[Id == "", `:=`(Id = WGSid, WGSid = V4)]
key[, V4 := NULL]

# Most rows have a corrupted WGSid, which contains the ID twice, separated by an underscore. Let's fix that.
key[, simple_WGSid := str_match(WGSid, "(.+[-_].+)_\\1")[,2]]
key[!is.na(simple_WGSid), WGSid := simple_WGSid]
key[, simple_WGSid := NULL]
key_vec <- key$Id
names(key_vec) <- key$WGSid

wgs_ids <- str_split_fixed(filenames, "\\.", n=2)[,1]
sample_ids <- key_vec[wgs_ids]
# Restore IDs that cannot be translated
sample_ids[is.na(sample_ids)] <- wgs_ids[is.na(sample_ids)]

names(filenames) <- sample_ids

read_bed <- function(filename) {
  bed <- fread(filename)
  if (nrow(bed) > 0) as.numeric(bed[[4]]) else NULL
}

genotypes <- filenames %>%
  lapply(read_bed) %>%
  as.data.table()

first_table <- fread(filenames[1])
genotypes <- first_table[, .(chr = V1, start = V2, end=V3)] %>%
  cbind(genotypes)

write.table(genotypes, "cnv_matrix.txt", sep="\t", quote=F, row.names=F)
