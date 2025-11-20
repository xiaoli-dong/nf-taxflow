process GTDBTK_ANIREP {
    tag "${meta.id}"
    label 'process_high_memory'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gtdbtk:2.5.2--pyh1f0d9b5_0' :
        'biocontainers/gtdbtk:2.5.2--pyh1f0d9b5_0' }"

    // --------------------------
    // INPUT
    // --------------------------
    input:
    tuple val(meta), path(contigs, stageAs: "input_dir/*")
    path(db)

    // --------------------------
    // OUTPUT
    // --------------------------
    output:
    tuple val(meta), path("*.ani_closest.tsv"),       emit: closest
    tuple val(meta), path("*.ani_summary.tsv"),       emit: summary
    tuple val(meta), path("*.json"),                  emit: json
    tuple val(meta), path("${prefix}.log"),           emit: log
    tuple val(meta), path("${prefix}.warnings.log"),  emit: warnings
    path ("versions.yml"),                                      emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args ?: ''
    prefix          = task.ext.prefix ?: "${meta.id}"

    // Auto-detect a suffix from the *first* contig
    def first = contigs[0]
    def contig_name = first.getName()

    def suffix =
        contig_name.endsWith(".fa.gz")     ? "fa.gz"     :
        contig_name.endsWith(".fna.gz")    ? "fna.gz"    :
        contig_name.endsWith(".fasta.gz")  ? "fasta.gz"  :
        contig_name.endsWith(".fa")        ? "fa"        :
        contig_name.endsWith(".fna")       ? "fna"       :
        contig_name.endsWith(".fasta")     ? "fasta"     :
        null

    if (suffix == null)
        error "ERROR: Could not determine FASTA suffix for first genome: ${contig_name}"

    log.info "GTDBTK_ANIREP: detected genome suffix '${suffix}' for group ${meta.id}"

    def suffix_opt = "-x ${suffix}"
 //--prefix ${meta.id} \\
    """
    # Set GTDB database path
    export GTDBTK_DATA_PATH="\$(find -L ${db} -maxdepth 2 -name 'metadata' -type d -exec dirname {} \\;)"

    # Run GTDB-Tk ANI REP on *all* genomes in input_dir/
    gtdbtk ani_rep \\
        ${args} \\
        ${suffix_opt} \\
        --genome_dir input_dir \\
        --out_dir ./ \\
        --cpus ${task.cpus}

    # Normalize filenames
    mv gtdbtk.log             ${prefix}.log
    mv gtdbtk.warnings.log    ${prefix}.warnings.log
    mv gtdbtk.json            ${prefix}.json
    mv gtdbtk.ani_summary.tsv ${prefix}.ani_summary.tsv
    mv gtdbtk.ani_closest.tsv ${prefix}.ani_closest.tsv

    # Version file
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: \$(echo \$(gtdbtk --version 2>/dev/null) | sed "s/gtdbtk: version //; s/ Copyright.*//")
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    """

    touch ${prefix}.ani_summary.tsv
    touch ${prefix}.ani_closest.tsv
    touch ${prefix}.log
    touch ${prefix}.json
    touch ${prefix}.warnings.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gtdbtk: "stub"
    END_VERSIONS
    """
}
