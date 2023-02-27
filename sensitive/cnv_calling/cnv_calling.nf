nextflow.enable.dsl=2

process extract_reads {
  cpus 8
  time '2h'
  publishDir "${params.out}/roots", mode: 'copy'

  input:
    path bam
  output:
    path '*.root'
  shell:
    template 'extract_reads.sh'
}

process quality_control {
  cpus 1
  time '30m'
  publishDir "${params.out}/qc", mode: 'copy'
  beforeScript 'ml R_packages'

  input:
    path variants
  output:
    path '*_variants_qc.bed'
  shell:
    template 'qc.R'
}

process cnvnator {
  cpus 4
  time '4h'
  publishDir "${params.out}/raw", mode: 'copy'
  stageInMode 'copy'
  
  input:
    path root
    path reference
  output:
    path '*_variants.txt', emit: variants
    path '*stats.txt', emit: stats
  shell:
    template 'cnvnator.sh'
}

process combine_stats {
  cpus 1
  time '10m'
  publishDir "${params.out}", mode: 'copy'
  
  input:
    path stats
  output:
    path 'bin_stats.txt'
  script:
    "cat $stats > bin_stats.txt"
}

workflow call_cnvs {
  take:
    bams
    reference
  main:
    extract_reads(bams)
    cnvnator(extract_reads.out, reference)
    statsList = cnvnator.out.stats.toList()
    combine_stats(statsList)
    quality_control(cnvnator.out.variants)
  emit:
    raw_variants = cnvnator.out.variants
    qc_variants = quality_control.out
}

workflow {
  bams = Channel.fromPath(params.bams)
  call_cnvs(bams, params.reference)
}
