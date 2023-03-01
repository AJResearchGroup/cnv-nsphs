nextflow.enable.dsl=2

process gwas_single_chromosome {
  cpus 8
  time '10h'
  beforeScript 'ml R_packages'
  publishDir params.gwas_out, mode: 'copy'

  input:
    path cnv_matrix
    path phenotypes
    path covariates
    each chromosome
  output:
    path '*.glm'
  shell:
    template 'gwas.R'
}

process merge_gwas_results {
  cpus 2
  time '1h'
  beforeScript 'ml R_packages'
  publishDir params.gwas_out, mode: 'copy'

  input:
    path '*.glm'
  output:
    path 'gwas.RDS'
    path 'significan_cnvs.txt'
  shell:
    template 'merge_results.R'
}

workflow gwas { 
  take:
    cnv_matrix
    pheno
    covariates
    chromosomes
  main:
    gwas_single_chromosome(cnv_matrix, pheno, covariates, chromosomes)
    merge_gwas_results(gwas_single_chromosome.out.collect())
  emit:
    merge_gwas_results.out
}

workflow {
  gwas(
    Channel.fromPath(params.cnv_matrix),
    Channel.fromPath(params.phenotypes),
    Channel.fromPath(params.covariates),
    Channel.of(params.chromosomes)
  )
}
