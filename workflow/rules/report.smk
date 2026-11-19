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
        # DP and AF may live in INFO or in FORMAT (e.g. Clair3 output).
        HDR="$(bcftools view -h {input})"
        DP='.'
        AF='.'
        if printf '%s\\n' "$HDR" | grep -q '^##INFO=<ID=DP,'; then
            DP='%INFO/DP'
        elif printf '%s\\n' "$HDR" | grep -q '^##FORMAT=<ID=DP,'; then
            DP='[%DP]'
        fi
        if printf '%s\\n' "$HDR" | grep -q '^##INFO=<ID=AF,'; then
            AF='%INFO/AF'
        elif printf '%s\\n' "$HDR" | grep -q '^##FORMAT=<ID=AF,'; then
            AF='[%AF]'
        fi
        ( printf 'chrom\\tpos\\tref\\talt\\tqual\\tfilter\\tdp\\taf\\n'; \
          bcftools query \
            -f "%CHROM\\t%POS\\t%REF\\t%ALT\\t%QUAL\\t%FILTER\\t$DP\\t$AF\\n" \
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
