# Rule 1 — quality-filter the raw VCF with bcftools.


rule filter_vcf:
    input:
        INPUT_VCF
    output:
        FILTERED
    container:
        config["containers"]["bcftools"]
    params:
        min_qual  = config["filter"]["min_qual"],
        pass_only = "-f PASS" if config["filter"]["pass_only"] else ""
    shell:
        """
        bcftools view -i 'QUAL>={params.min_qual}' {params.pass_only} -Ov \
            -o {output} {input}
        """
