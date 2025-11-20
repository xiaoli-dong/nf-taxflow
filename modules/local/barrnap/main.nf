process BARRNAP {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/barrnap:0.9--hdfd78af_4' :
        'biocontainers/barrnap:0.9--hdfd78af_4' }"

    input:
    tuple val(meta), path(contigs)
    path(metapackage)

    output:
    tuple val(meta), path('${prefix}.fasta'), emit: fasta
    tuple val(meta), path('${prefix}.gff'),   emit: gff
    path "versions.yml"           , emit: versions


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"


    """
    barrnap $args \\
        --threads $task.cpus \\
        --outseq ${prefix}_rrna.fasta \\
        ${contigs} \\
        > ${prefix}_rrna.gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        \$(barrnap --version)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_rrna.fasta
    touch ${prefix}_rrna.gff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        \$(barrnap --version)
    END_VERSIONS
    """

}
