# Shared paths and helpers. Included first by Snakefile.

import os

SAMPLE  = os.environ.get("VCF_ANNOTATE_SAMPLE", config["sample"])
RESULTS = os.environ.get("VCF_ANNOTATE_OUT", config["results_dir"])
MODE    = os.environ.get("VCF_ANNOTATE_MODE",
                         config["annotation"]["mode"]).lower()
CACHE   = os.path.expanduser(config["annotation"]["cache_dir"])

INPUT_VCF = os.environ.get("VCF_ANNOTATE_INPUT",
                           f"{config['input_dir']}/{SAMPLE}.vcf")
FILTERED  = f"{RESULTS}/{SAMPLE}.filtered.vcf"
TABLE     = f"{RESULTS}/{SAMPLE}.variants.tsv"
VEP_TSV   = f"{RESULTS}/{SAMPLE}.vep.tsv"
SUMMARY   = f"{RESULTS}/{SAMPLE}.summary.md"


def final_outputs():
    """Files produced by `make run`."""
    outs = [TABLE, SUMMARY]
    if MODE == "vep":
        outs.append(VEP_TSV)
    return outs


def summary_inputs(wildcards):
    xs = [TABLE]
    if MODE == "vep":
        xs.append(VEP_TSV)
    return xs


# Bind the VEP cache into the container only in VEP mode.
singularity_args: f"--bind {CACHE}:/vep_cache" if MODE == "vep" else ""
