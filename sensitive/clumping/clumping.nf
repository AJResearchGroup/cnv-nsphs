nextflow.enable.dsl=2

process clump_cnvs {

  cpus 8
  time '2h'
  publishDir "${params.out}/clumping", mode: 'copy'
  beforeScript 'ml R_packages'

  input:
    path gwas_results
    path cnv_matrix
  output:
    path "clumps.txt"
  shell:
    template 'clumping.R'
}

workflow clumping {
  take:
    gwas_results
    cnv_matrix
  main:
    clump_cnvs(gwas_results, cnv_matrix)
  emit:
    clump_cnvs.out
  
}

workflow {

}