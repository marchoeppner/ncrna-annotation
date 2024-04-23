/* 
~~~~~~~~~~~~~~~~
Include modules
~~~~~~~~~~~~~~~~
*/
include { INPUT_CHECK }                     from './../modules/input_check'
include { MULTIQC }                         from './../modules/multiqc'
include { CUSTOM_DUMPSOFTWAREVERSIONS }     from './../modules/custom/dumpsoftwareversions'
include { GUNZIP as GUNZIP_RFAM_CM }        from './../modules/gunzip'
include { GUNZIP as GUNZIP_RFAM_FAMILY }    from './../modules/gunzip'
include { HELPER_RFAMTOGFF }                from './../modules/helper/rfamtogff'
include { INFERNAL_PRESS }                  from './../modules/infernal/press'
include { INFERNAL_SEARCH }                 from './../modules/infernal/search'
include { FASTASPLITTER }                   from './../modules/helper/fastasplitter'

ch_multiqc_config = params.multiqc_config   ? Channel.fromPath(params.multiqc_config, checkIfExists: true).collect() : Channel.value([])
ch_multiqc_logo   = params.multiqc_logo     ? Channel.fromPath(params.multiqc_logo, checkIfExists: true).collect() : Channel.value([])

rfam_cm_gz      = params.rfam_cm ? Channel.fromPath(params.rfam_cm)         : Channel.fromPath(params.references["rfam"].rfam_cm)
rfam_family_gz  = params.rfam_family ? Channel.fromPath(params.rfam_family) : Channel.fromPath(params.references["rfam"].rfam_family)

samplesheet     = params.input ? Channel.fromPath(params.input)             : Channel.from([])

ch_versions = Channel.from([])
multiqc_files = Channel.from([])

workflow NCRNA_ANNOTATION {
  
    main:

    INPUT_CHECK(samplesheet)

    FASTASPLITTER(
        INPUT_CHECK.out.fasta,
        params.fasta_chunk_size
    )

    FASTASPLITTER.out.chunks.branch { m,f ->
        single: f.getClass() != ArrayList
        multi: f.getClass() == ArrayList
    }.set { ch_fa_chunks }
    ch_versions = ch_versions.mix(FASTASPLITTER.out.versions)

    ch_fa_chunks.multi.flatMap { h,fastas ->
        fastas.collect { [ h,file(it)] }
    }.set { ch_chunks_split }

    GUNZIP_RFAM_CM(
        rfam_cm_gz.map { f ->
            [ 
                [ id: f.getSimpleName()],
                f
            ]
        }
    )
    ch_versions = ch_versions.mix(GUNZIP_RFAM_CM.out.versions)

    GUNZIP_RFAM_FAMILY(
       rfam_family_gz.map { f ->
            [ 
                [ id: f.getSimpleName()],
                f
            ]
       }
    )
    ch_versions = ch_versions.mix(GUNZIP_RFAM_FAMILY.out.versions)

    INFERNAL_PRESS(
        GUNZIP_RFAM_CM.out.gunzip
    )

    ch_chunks_combined = ch_chunks_split.mix(ch_fa_chunks.single)

    INFERNAL_SEARCH(
        ch_chunks_combined,
        INFERNAL_PRESS.out.cm.collect()
    )

    INFERNAL_SEARCH.out.tbl
    .groupTuple()
    .multiMap { m,t ->
        metadata: [m.id, m]
        tbl: [m.id,t ]
    }.set { ch_rfam_tbls }

    ch_rfam_tbls.tbl.collectFile { mkey, file -> [ "${mkey}.rfam.tbl", file ] }
    .map { file -> [ file.simpleName, file ] }
    .set { ch_merged_tbls }

    ch_rfam_tbls.metadata.join(
        ch_merged_tbls
    )
    .map { k,m,f -> tuple(m,f) }
    .set { ch_rfam_gff }

    HELPER_RFAMTOGFF(
        ch_rfam_gff,
        GUNZIP_RFAM_FAMILY.out.gunzip.map{m,f -> f}
    )

    CUSTOM_DUMPSOFTWAREVERSIONS(
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    multiqc_files = multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml)

    MULTIQC(
        multiqc_files.collect(),
        ch_multiqc_config,
        ch_multiqc_logo
    )

    emit:
    qc = MULTIQC.out.html
}
