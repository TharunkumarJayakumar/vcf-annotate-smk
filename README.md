# vcf-annotate-smk

[![CI](https://github.com/TharunkumarJayakumar/vcf-annotate-smk/actions/workflows/ci.yml/badge.svg)](https://github.com/TharunkumarJayakumar/vcf-annotate-smk/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A small, reproducible Snakemake workflow that takes a VCF file and produces a
quality-filtered variant table, Ensembl VEP annotation and a one-page summary.

*One VCF in, four tidy files out. No custom API client, no web server, no 700-line annotator.*

The workflow is intentionally minimal: every analysis step is an off-the-shelf
bioinformatics tool pinned to a [BioContainers](https://biocontainers.pro/) image.
The only custom code is a 67-line Python script that formats the summary.

---

## Table of contents

- [Requirements](#requirements)
- [Installation](#installation)
  - [Install from source](#install-from-source)
  - [Pull the container images](#pull-the-container-images)
  - [Get the VEP cache (one time)](#get-the-vep-cache-one-time)
- [Quick usage examples](#quick-usage-examples)
- [How it works](#how-it-works)
  - [Rule 1: filter_vcf](#rule-1-filter_vcf)
  - [Rule 2: annotate_vep](#rule-2-annotate_vep)
  - [Rule 3: make_table](#rule-3-make_table)
  - [Rule 4: make_summary](#rule-4-make_summary)
- [Output files](#output-files)
- [Configuration](#configuration)
- [Testing](#testing)
- [Known limitations](#known-limitations)
- [Project layout](#project-layout)
- [Acknowledgements](#acknowledgements)
- [License](#license)

---

## Requirements

- Linux or macOS
- Python 3.9 or later
- [Snakemake](https://snakemake.readthedocs.io/) 7 or later (tested with 9.23)
- [Apptainer/Singularity](https://apptainer.org/) or Docker
- A one-time download of the Ensembl VEP GRCh38 cache for full annotation

No other Python packages are needed by the workflow itself. `pytest` is only
needed to run the tests.

---

## Installation

### Install from source

```bash
git clone https://github.com/TharunkumarJayakumar/vcf-annotate-smk.git
cd vcf-annotate-smk
pip install snakemake pytest
snakemake --version
```

### Pull the container images

```bash
make setup
```

This pulls the two pinned images:

| Tool | Image |
|---|---|
| bcftools | `docker://quay.io/biocontainers/bcftools:1.25--h118bc1c_1` |
| Ensembl VEP | `docker://quay.io/biocontainers/ensembl-vep:116.3--pl5321h663502d_0` |

Snakemake can also pull them automatically on first run. With Docker instead of
Apptainer, run `make run` with `--sdm docker`.

### Get the VEP cache (one time)

VEP needs reference data. Install it once with the `vep_install` helper from the
`ensembl-vep` conda package:

```bash
conda install -c bioconda ensembl-vep
vep_install -a cf -s homo_sapiens -y GRCh38 -c ~/vep_cache --CONVERT
```

If you only want to try the workflow without any external data, skip this step
and use `make demo` (see below).

---

## Quick usage examples

Check the workflow graph without running anything:

```bash
make dry-run
```

Run the bundled example **without** the VEP cache (filter + table + summary):

```bash
make demo
```

Run the full pipeline including VEP annotation:

```bash
make run
```

Use your own VCF:

```bash
cp /path/to/my_sample.vcf assets/
# then set `sample: my_sample` in config/config.yaml
make run
```

Run with a different assembly (after downloading the matching cache):

```bash
# edit config/config.yaml: annotation.assembly and annotation.cache_version
make run
```

---

## How it works

The workflow is a four-step DAG. Rules live in separate files under
`workflow/rules/`, following the nf-core/Nextflow module convention.

### Rule 1: filter_vcf

Runs `bcftools view` inside the bcftools container. Keeps only sites with
`QUAL >= min_qual` and (by default) `FILTER == PASS`, and writes a plain VCF.

### Rule 2: annotate_vep

Runs Ensembl VEP inside the VEP container in offline cache mode. Adds gene
symbol, HGVS notation, protein position and consequence. The VEP cache is bind-
mounted into the container at `/vep_cache`.

This rule is skipped when `VCF_ANNOTATE_MODE=skip` is set.

### Rule 3: make_table

Runs `bcftools query` to flatten the filtered VCF into a header-bearing TSV with
`chrom, pos, ref, alt, qual, filter, dp, af` columns.

### Rule 4: make_summary

Runs `workflow/scripts/make_summary.py` (Python standard library only) to
produce a Markdown report with variant counts, mean quality, per-chromosome
counts and the first ten variants.

---

## Output files

All outputs go to `results/`:

| File | Description |
|---|---|
| `<sample>.filtered.vcf` | VCF after quality/filter filtering |
| `<sample>.variants.tsv` | Flat, machine-readable variant table |
| `<sample>.vep.tsv` | Ensembl VEP tab output (full mode only) |
| `<sample>.summary.md` | Human-readable one-page summary |

---

## Configuration

Everything is in `config/config.yaml`:

```yaml
sample: example                  # input is {input_dir}/{sample}.vcf
input_dir: assets
results_dir: results

filter:
  min_qual: 20                   # drop variants below this QUAL
  pass_only: true                # require FILTER == PASS

annotation:
  mode: vep                      # vep | skip
  assembly: GRCh38
  cache_dir: "~/vep_cache"
  cache_version: "116"

containers:
  bcftools: "docker://quay.io/biocontainers/bcftools:1.25--h118bc1c_1"
  vep: "docker://quay.io/biocontainers/ensembl-vep:116.3--pl5321h663502d_0"
```

For a cache-free run, set `VCF_ANNOTATE_MODE=skip` in the environment (that is
what `make demo` does). This overrides `annotation.mode` without editing the
file.

---

## Testing

```bash
make test
```

This runs three unit tests for the summary script and a Snakemake DAG dry-run.
The same command runs in GitHub Actions on every push and pull request.

---

## Known limitations

- The default cache is **human GRCh38**. Other assemblies work if you download
  the matching cache and change `annotation.assembly` / `cache_version`.
- This is a **workflow wrapper**, not a new variant-effect algorithm. Its value
  is reproducibility and convenience.
- The VEP cache is large (~several GB) and must be downloaded once.
- `annotation.mode: skip` produces no biological annotation — it is meant for
  demos and CI.
- No pathogenicity or population-frequency columns are added by the summary;
  those come from VEP's own output file.

---

## Project layout

```
vcf-annotate-smk/
├── config/
│   └── config.yaml              # all settings (like nextflow.config)
├── workflow/
│   ├── Snakefile                # entry point (like main.nf)
│   ├── rules/                   # one file per process (like modules/)
│   │   ├── common.smk
│   │   ├── filter.smk
│   │   ├── annotate.smk
│   │   └── report.smk
│   └── scripts/
│       └── make_summary.py      # the only custom code
├── assets/example.vcf
├── tests/
├── .github/workflows/ci.yml
├── Makefile
├── LICENSE
└── CITATION.cff
```

---

## Acknowledgements

- [Ensembl VEP](https://www.ensembl.org/info/docs/tools/vep/) for variant annotation.
- [BioContainers](https://biocontainers.pro/) for version-pinned, reproducible tool images.
- [Snakemake](https://snakemake.readthedocs.io/) and the nf-core community for the workflow conventions.
- The README structure was inspired by Ryan Wick's [Porechop](https://github.com/rrwick/Porechop) repository.

---

## License

MIT — see [LICENSE](LICENSE). If you use this workflow, please cite the
[CITATION.cff](CITATION.cff) file.
