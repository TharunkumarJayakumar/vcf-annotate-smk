# vcf-annotate-smk

**A minimal, containerised Snakemake workflow for VCF annotation.**

It takes one VCF, filters it, annotates it with Ensembl VEP, and writes a flat
table plus a one-page Markdown summary.

> Human · GRCh38 · 4 rules · 2 container images · 1 small Python helper.

---

## Why this exists

After variant calling you have a VCF — a list of positions. You still need to
answer *"which gene, what consequence, is it common?"*. That normally means
manually querying several databases. This workflow does it in one reproducible
command, with the tools pinned to container images instead of relying on whatever
happens to be installed on your machine.

It is deliberately small: no web server, no custom API client, no 700-line
annotator. Each step is an off-the-shelf bioinformatics tool pulled from
[BioContainers](https://biocontainers.pro/).

---

## Project layout

The structure follows the nf-core / Nextflow convention:

```
vcf-annotate-smk/
├── config/
│   └── config.yaml            # all settings (like nextflow.config)
├── workflow/
│   ├── Snakefile              # entry point (like main.nf)
│   └── rules/                 # one file per process (like modules/)
│       ├── common.smk
│       ├── filter.smk
│       ├── annotate.smk
│       └── report.smk
│   └── scripts/
│       └── make_summary.py    # ~65 lines, standard library only
├── assets/example.vcf         # small example input
├── tests/                     # unit tests + smoke test
├── .github/workflows/ci.yml
├── Makefile
├── LICENSE
└── CITATION.cff
```

---

## Quick start

Requirements: `snakemake`, `singularity`/`apptainer` (or `docker`), Python 3.9+.

```bash
# 1. clone and enter
git clone https://github.com/YOUR_USERNAME/vcf-annotate-smk.git
cd vcf-annotate-smk

# 2. check the workflow graph
make dry-run

# 3. pull the container images (optional; Snakemake can pull on demand)
make setup

# 4. run on the bundled example
make run
```

To use your own data, put `my_sample.vcf` in `assets/` and set `sample: my_sample`
in `config/config.yaml`.

---

## Configuration

Everything is in `config/config.yaml`:

| Key | Meaning |
|---|---|
| `sample`, `input_dir` | Input is `{input_dir}/{sample}.vcf` |
| `filter.min_qual` | Drop variants below this QUAL |
| `annotation.mode` | `vep` (annotate) or `skip` (filter + table only) |
| `annotation.assembly` | `GRCh38` by default |
| `annotation.cache_dir` | Where the one-time VEP cache lives |
| `containers.*` | Version-pinned `docker://` image URLs |

### The one-time VEP cache

VEP needs reference data. Download it once:

```bash
vep_install -a cf -s homo_sapiens -y GRCh38 -c ~/vep_cache --CONVERT
```

For a quick demo without any external data:

```bash
make demo
# equivalent to: VCF_ANNOTATE_MODE=skip snakemake --cores 4
```

---

## The four rules

| Rule | Tool (container) | Output |
|---|---|---|
| `filter_vcf` | `bcftools` | `results/<sample>.filtered.vcf` |
| `annotate_vep` | `ensembl-vep` | `results/<sample>.vep.tsv` |
| `make_table` | `bcftools query` | `results/<sample>.variants.tsv` |
| `make_summary` | Python helper | `results/<sample>.summary.md` |

---

## Outputs

`variants.tsv` — one row per variant: `chrom, pos, ref, alt, qual, filter, dp, af`.

`vep.tsv` — Ensembl VEP's tab output (gene symbol, HGVS, protein position, etc.).

`summary.md` — counts, mean QUAL, per-chromosome table, first 10 variants.

---

## Tests

```bash
make test     # unit tests + Snakemake DAG dry-run
```

CI runs the same command on every push.

---

## Scope and limitations

- Built for **human GRCh38** because that is what the VEP cache provides.
  Other assemblies work if you download the matching cache and change
  `annotation.assembly` / `cache_version`.
- It is a **workflow wrapper**, not a new algorithm. The scientific value is
  reproducibility and convenience.
- Only variants present in the input VCF are reported; no genotype refinement.

---

## License and citation

MIT — see [LICENSE](LICENSE). If you use it, please cite the
[CITATION.cff](CITATION.cff) file.
