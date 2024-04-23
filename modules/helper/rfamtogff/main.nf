process HELPER_RFAMTOGFF {
    tag 'Rfam14'
    label 'short_serial'
    
    executor 'local'

    conda "${modulrDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.12--pyhdfd78af_0':
        'quay.io/biocontainers/multiqc:1.12--pyhdfd78af_0' }"

    input:
    tuple val(meta),path(tbl)
    path(families)

    output:
    path("*.gff"), emit: gff    
    path "versions.yml"           , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def gff = prefix + ".rfam.gff"

    // If no ncRNAs were found, emit an empty gff3 file with header
    """
    rfam2gff.pl --infile $tbl --family $families > $gff
    test -f ${gff} || echo "##gff-version 3" >> $gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        helper: ${workflow.manifest.version}
    END_VERSIONS
    """
}
