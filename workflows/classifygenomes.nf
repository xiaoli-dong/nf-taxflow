/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { paramsSummaryMap } from 'plugin/nf-schema'
include { paramsSummaryMultiqc } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_taxflow_pipeline'
include { GTDBTK_ANIREP } from '../modules/local/gtdbtk/anirep/main'
include { BARRNAP } from '../modules/local/barrnap/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/



workflow CLASSIFYGENOMES {
    take:
    fasta_contigs // channel: samplesheet read in from --input

    main:

    ch_versions = channel.empty()

    if (!params.skip_gtdbtk) {
        //To run GTDB-Tk ANI REP once on ALL genomes together
        fasta_contigs
            .map { meta, fasta -> fasta }
            .collect()
            .map { list -> tuple([id: "gtdbtk_anirep_report"], list) }
            .set { ch_all_genomes }
        ch_all_genomes.view()
        GTDBTK_ANIREP(
            ch_all_genomes,
            params.gtdbtk_db,
        )

        ch_versions = ch_versions.mix(GTDBTK_ANIREP.out.versions)
    }


    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'taxflow_software_' + 'mqc_' + 'versions.yml',
            sort: true,
            newLine: true,
        )

    emit:
    versions = ch_versions // channel: [ path(versions.yml) ]
}
