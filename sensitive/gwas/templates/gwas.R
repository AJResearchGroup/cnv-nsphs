#!Rscript
library(foreach)
library(data.table)
library(doParallel)
library(magrittr)

#Sys.getenv("SLURM_CPUS_PER_TASK", unset = 1) %>%
#  as.integer() %>%
#  registerDoParallel()

parallel::makeCluster(4) |>
  registerDoParallel()

load("!{phenotypes}")
covariates <- read.csv(file="!{covariates}", header=TRUE, sep=",")
CNVbed <- fread("!{cnv_matrix}")

LR_function <- function(BioMarker, CNVbed, covariates, Chrom) {
  #Select by chromosome:
  CNVbed <- CNVbed[chr==Chrom]
  cnv_coordinates <- CNVbed[, .(chr, start, end)]

  # Format data:
  rownames(covariates) <- covariates$id
  covariates$id <- NULL
  complete_samples <- intersect(rownames(BioMarker), names(CNVbed)) |> intersect(rownames(covariates))
  CNVbed <- CNVbed[ , names(CNVbed) %in% complete_samples, with=FALSE]
  covariates <- covariates[rownames(covariates) %in% complete_samples, ]
  BioMarker <- BioMarker[rownames(BioMarker) %in% complete_samples, ]
  CNVbed <- CNVbed[rowSums(is.na(CNVbed))/length(CNVbed)<0.1, ]
  #BioMarker <- BioMarker[ ,colSums(is.na(BioMarker))/nrow(BioMarker)<0.1]
  CNVbed <- CNVbed[ ,order(names(CNVbed)), with=FALSE]
  CNVbed <- CNVbed[, !duplicated(names(CNVbed)), with=FALSE]
  covariates <- covariates[order(rownames(covariates)), ] |> as.matrix()
  BioMarker <- BioMarker[order(rownames(BioMarker)), ]
  copy_numbers <- CNVbed |> as.matrix() |> t()
  #Sex <- covariates[ ,2] # Population Sex
  #Age <- covariates[ ,3] # Population Age
  
  foreach (i = seq_len(ncol(copy_numbers)), .combine=rbind, .packages="data.table") %:%
    foreach (i1 = seq_len(ncol(BioMarker)), .combine=rbind, .packages="data.table") %dopar% {
      CNV <- copy_numbers[, i] # index CNV
      Y <- BioMarker[ ,i1] #index biomarkder
      model1 <- glm( Y ~ CNV + covariates, family = gaussian, na.action = na.omit)
      coefs <- summary(model1)$coef[2, 1:4]

      cnv_coordinates[i, .(
        chr,
        start,
        end,
        marker = colnames(BioMarker)[i1],
        N = nobs(model1),
        beta = coefs[1],
        se = coefs[2],
        t = coefs[3],
        p = coefs[4]
      )]
    }
}

gwas_results <- LR_function(pea_3, CNVbed, covariates, "!{chromosome}")
write.table(gwas_results, "!{chromosome}.glm", sep="\t", quote=F, row.names=F)
