find_independent <-
function(sig) {
lead <- sig[which.min(sig$p), ]
chr <- as.character(lead@seqnames)
which(ld[[chr]][lead$id,]^2 < .1)
}
