nextflow.enable.dsl=2

process filter_cnvs {
  cpus 1
  time '10m'
  beforeScript 'ml R_packages'

  input:
    path variants
  output:
    path "*_filtered.bed"
  shell:
    template 'filter_variants.R'
}

process make_windows {
  cpus 4
  time '30m'

  input:
    path variants
  output:
    path 'windows.bed'
  shell:
    template 'makewindows.sh'
}

process align_cnvs {
  cpus 2
  time '1h'
  publishDir "${params.out}/aligned", mode: 'copy'

  input:
    path variants
    path windows
    val sample_size
  output:
    path '*_200bp.bed'
  shell:
    template 'align_cnvs.sh'
}

process assemble_matrix {
  cpus 16
  time '3h'
  publishDir "${params.out}/matrix", mode: 'copy'
  beforeScript 'ml R_packages'

  input:
    path bed_files
    path translation_key
  output:
    path 'cnv_matrix.txt'
  shell:
    template 'assemble_matrix.R'
}

process collapse_matrix {
  cpus 4
  time '1h'
  publishDir "${params.out}/matrix", mode: 'copy'

  input:
    path cnv_matrix
  output:
    path 'cnv_matrix_collapsed.txt'
  shell:
    template 'collapse_matrix.sh'
}

workflow create_matrix {
  take:
    raw_variants
    qc_variants
    translation_key
  main:
    filter_cnvs(raw_variants)
    filtered_cnvs = filter_cnvs.out.collect()
    num_samples = filtered_cnvs.size()
    make_windows(filtered_cnvs)
    align_cnvs(qc_variants, make_windows.out, num_samples)
    assemble_matrix(align_cnvs.out.collect(), translation_key)
    collapse_matrix(assemble_matrix.out)
  emit:
    collapse_matrix.out
}

workflow {
  raw_channel = Channel.fromPath(params.raw_variants)
  qc_channel = Channel.fromPath(params.qc_variants)
  translation_channel = Channel.fromPath(params.translation_key)
  create_matrix(raw_channel, qc_channel, translation_channel)
  create_matrix.out.view()
}
