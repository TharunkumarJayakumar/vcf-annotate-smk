# Rule 2 — annotate with Ensembl VEP (containerised, offline cache).


rule annotate_vep:
    input:
        FILTERED
    output:
        VEP_TSV
    container:
        config["containers"]["vep"]
    params:
        assembly = config["annotation"]["assembly"],
        version  = config["annotation"]["cache_version"]
    shell:
        """
        vep -i {input} -o {output} \
            --tab --cache --offline --no_stats \
            --dir_cache /vep_cache \
            --cache_version {params.version} \
            --assembly {params.assembly} \
            --symbol --numbers --canonical --protein
        """
