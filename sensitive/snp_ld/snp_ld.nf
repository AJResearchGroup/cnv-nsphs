nextflow.enable.dsl=2

process extract_genotypes {
    cpus 8
    time '1h'

    input:
      val bfile
    output:
      path "*.raw"
    shell:
      template "extract_genotypes.sh"
}

process merge_genotypes {
    cpus 8
    time '10m'

    input:
      path "geno*.raw"
    output:
      path "combined.raw"
    shell:
      template "merge_genotypes.R"
}

process calculate_ld {
    cpus 8
    time '1h'

    publishDir "cnv_calls/ld", mode: 'copy'

    input:
      path snps
      path cnvs
      path colocalizations
    output:
      path "ld.txt"
    shell:
      template "calculate_snp_ld.R"
}

workflow snp_ld {
  take:
    plink_filesets
    cnv_matrix
    colocalizations
  
  main:
    extract_genotypes(plink_filesets)
    merge_genotypes(extract_genotypes.out.collect())
    calculate_ld(merge_genotypes.out, cnv_matrix, colocalizations)
  
  emit:
    calculate_ld.out
}

workflow {
  snp_ld(params.plink_filesets, params.cnv_matrix, params.colocalizations)
}