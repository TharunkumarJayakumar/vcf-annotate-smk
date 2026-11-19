# Rules 3 and 4 — make a flat table and a Markdown summary.


rule make_table:
    input:
        FILTERED
    output:
        TABLE
    container:
        config["containers"]["bcftools"]
    shell:
        """
        ( printf 'chrom\\tpos\\tref\\talt\\tqual\\tfilter\\tdp\\taf\\n'; \
          bcftools query \
            -f '%CHROM\\t%POS\\t%REF\\t%ALT\\t%QUAL\\t%FILTER\\t%INFO/DP\\t%INFO/AF\\n' \
            {input} ) > {output}
        """


rule make_summary:
    input:
        summary_inputs
    output:
        SUMMARY
    params:
        extra = lambda wildcards, input: f"--vep {input[1]}" if MODE == "vep" else ""
    shell:
        """
        python workflow/scripts/make_summary.py \
            --table {input[0]} --out {output} {params.extra}
        """
