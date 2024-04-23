//
// Check input samplesheet and get read channels
//

workflow INPUT_CHECK {
    take:
    samplesheet // file: /path/to/samplesheet.csv

    main:
    samplesheet
        .splitCsv(header:true, sep:',')
        .map { row -> fasta_channel(row) }
        .set { fasta }

    emit:
    fasta // channel: [ val(meta), fasta ]
}

// Function to get list of [ meta, [ fastq_1, fastq_2 ] ]
def fasta_channel(LinkedHashMap row) {
    meta = [:]
    meta.id    = row.id
    
    if (!file(row.fasta).exists()) {
        exit 1, "ERROR: Fasta file does not exist for sample ${row.id}!"
    }

    array = [ meta, file(row.fasta) ]
    return array
}
