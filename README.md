# vcf-annotate-smk

[![CI](https://github.com/TharunkumarJayakumar/vcf-annotate-smk/actions/workflows/ci.yml/badge.svg)](https://github.com/TharunkumarJayakumar/vcf-annotate-smk/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**One VCF in. A results folder out.**

A small tool that filters a VCF, annotates variants with Ensembl VEP, and writes
a clean table plus a short report. All analysis tools are pinned to containers,
so it runs the same way on every machine.

---

## One command

```bash
./vcf-annotate -i my_variants.vcf
```

That is the whole thing. No config editing, no Snakemake commands, no container
commands.

A `results/` folder appears:

```
results/
├── my_variants.filtered.vcf    # VCF after quality filtering
├── my_variants.variants.tsv    # one row per variant
├── my_variants.vep.tsv         # gene / consequence / protein change from Ensembl VEP
└── my_variants.summary.md      # one-page human-readable report
```

### Input

Any plain VCF file — the output of your variant caller:

```
##fileformat=VCFv4.2
##reference=GRCh38
#CHROM  POS       ID        REF  ALT  QUAL  FILTER  INFO
chr1    925952    rs671     A    G    50    PASS    DP=100;AF=0.5
chr7    140453136 rs113488022 A  T    80    PASS    DP=120;AF=0.4
chr17   7577538   rs28934578 C  T    75    PASS    DP=85;AF=0.3
```

The table reads `DP` and `AF` from `INFO` when present, otherwise from
`FORMAT` (as in Clair3 output). Missing values are written as `.`.

### Output

`my_variants.variants.tsv`:

```
chrom   pos       ref  alt  qual  filter  dp   af
chr1    925952    A    G    50    PASS    100  0.5
chr7    140453136 A    T    80    PASS    120  0.4
chr17   7577538   C    T    75    PASS    85   0.3
```

`my_variants.summary.md`:

```
# VCF annotation summary

- Variants after filtering: **6**
- Mean quality (QUAL): **75.8**
- Chromosomes represented: **5**

## Variants per chromosome
| Chromosome | Variants |
|---|---:|
| chr17 | 2 |
| chr1  | 1 |
...
```

---

## What it does

```
my_variants.vcf
      │
      ├─ 1. filter      bcftools view    → keep QUAL ≥ 20, FILTER = PASS
      │
      ├─ 2. annotate    Ensembl VEP      → gene, consequence, protein change
      │
      ├─ 3. table       bcftools query   → flat TSV
      │
      └─ 4. summary     65-line Python   → Markdown report
```

Four steps, two container images, one small helper script. No custom API client.

---

## Options

```bash
./vcf-annotate --help
```

| Option | Meaning |
|---|---|
| `-i, --input FILE` | Input VCF (required) |
| `-o, --output DIR` | Output folder (default `results/`) |
| `--no-annotate` | Skip VEP — no cache or internet needed |
| `-t, --threads N` | CPU cores (default 4) |

Common examples:

```bash
# Try it on the bundled example, no setup needed
./vcf-annotate -i assets/example.vcf --no-annotate

# Your own VCF, custom output folder
./vcf-annotate -i /data/sample.vcf -o /data/annotated

# More CPU cores
./vcf-annotate -i sample.vcf -t 16
```

---

## Table of contents

- [Installation](#installation)
- [Full annotation (VEP cache)](#full-annotation-vep-cache)
- [Testing](#testing)
- [Project layout](#project-layout)
- [Known limitations](#known-limitations)
- [Acknowledgements](#acknowledgements)
- [License](#license)

---

## Installation

```bash
git clone https://github.com/TharunkumarJayakumar/vcf-annotate-smk.git
cd vcf-annotate-smk
pip install snakemake pytest
./vcf-annotate --help
```

Apptainer/Singularity or Docker is needed for the containerised tools. The
wrapper uses containers automatically when it finds Apptainer on your system.

---

## Full annotation (VEP cache)

Annotation needs a one-time reference download (~several GB):

```bash
make setup                       # pull the two container images
conda install -c bioconda ensembl-vep
vep_install -a cf -s homo_sapiens -y GRCh38 -c ~/vep_cache --CONVERT
./vcf-annotate -i my_variants.vcf
```

Without the cache, use `--no-annotate` — you still get the filtered VCF, the
TSV and the Markdown report.

---

## Testing

```bash
make test
```

Three unit tests plus a workflow dry-run. The same runs in GitHub Actions.

---

## Project layout

Most users only need `vcf-annotate` and this README. The rest is plumbing:

```
vcf-annotate-smk/
├── vcf-annotate              ← the command you run
├── config/config.yaml         settings (only for advanced use)
├── workflow/
│   ├── Snakefile              entry point
│   ├── rules/                 one file per step
│   └── scripts/make_summary.py
├── assets/example.vcf         example input
├── tests/                     3 unit tests
├── Makefile                   setup / test / dry-run
└── LICENSE, CITATION.cff
```

---

## Known limitations

- Human **GRCh38** by default; other assemblies need their own VEP cache.
  The wrapper checks the VCF header and stops if it says GRCh37/hg19.
- HGVS notation is **not** produced: Ensembl VEP needs an extra reference
  FASTA file for that. Gene symbol, consequence, cDNA/protein positions and
  amino-acid changes come from the cache.
- It is a thin workflow wrapper, not a new variant-effect algorithm.
- `--no-annotate` gives no biological annotation — it is for demos and CI.
- Pathogenicity and population frequencies, if needed, come from VEP's own
  output file.

---

## Acknowledgements

- [Ensembl VEP](https://www.ensembl.org/info/docs/tools/vep/) for annotation.
- [BioContainers](https://biocontainers.pro/) for reproducible tool images.
- [Snakemake](https://snakemake.readthedocs.io/) and nf-core for workflow conventions.
- README layout inspired by Ryan Wick's [Porechop](https://github.com/rrwick/Porechop).

---

## License

MIT — see [LICENSE](LICENSE). Please cite [CITATION.cff](CITATION.cff).
