nextflow.enable.dsl=2

include {call_cnvs} from './cnv_calling/cnv_calling.nf'
include {create_matrix} from './cnv_matrix/cnv_matrix.nf'
include {gwas} from './gwas/gwas.nf'

workflow {
  call_cnvs(
    Channel.fromPath(params.bams),
    Channel.fromPath(params.reference)
  )
  create_matrix(
    call_cnvs.out.raw_variants,
    call_cnvs.out.qc_variants,
    Channel.fromPath(params.translation_key)
  )
  gwas(
    create_matrix.out,
    Channel.fromPath(params.phenotypes),
    Channel.fromPath(params.covariates),
    Channel.of(params.chromosomes)
  )
}