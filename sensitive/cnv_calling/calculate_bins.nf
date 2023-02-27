nextflow.enable.dsl=2

include {extract_reads} from './cnv_calling'

process calculate_bins {
  cpus 4
  time '20m'
  input:
    path root
    path reference
  output:
    stdout
  shell:
    template 'calculate_bins.sh'
}

workflow {
  bams = Channel.fromPath(params.bams)
  extract_reads(bams)
  calculate_bins(extract_reads.out, Channel.value(params.reference))
  calculate_bins.out.collectFile(name: "bin_sizes.txt")
}
