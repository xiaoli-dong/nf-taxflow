process SSURRNA_GETTOPMATCHES {
    label 'process_single'

    conda "conda-forge::python=3.9.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.9--1' :
        'biocontainers/python:3.9--1' }"
    //-outfmt "6 qseqid qlen stitle pident length qcovs qstart qend sstart send evalue bitscore stitle"
    input:
    tuple val(meta), path(blastn_output)

    output:
    tuple val(meta), path("*.blastn.tsv"), emit: top_matches
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = '1.2' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.
    """
    summarize_16s_hits.py ${blastn_output} ${meta.id} > ${prefix}.blastn.tsv

    cat <<-END_VERSIONS > versions.yml
     "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.blastn.tsv

    cat <<-END_VERSIONS > versions.yml
     "${task.process}":
        python: \$(python --version | sed 's/Python //g')
    END_VERSIONS
    """
}
