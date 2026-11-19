#!/usr/bin/env python3
"""Turn the variant table into a short Markdown summary (stdlib only)."""

import argparse
import csv
from collections import Counter
from pathlib import Path


def read_tsv(path):
    with open(path, newline="") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--table", required=True, help="variants.tsv from make_table")
    parser.add_argument("--vep", help="optional VEP output TSV")
    parser.add_argument("--out", required=True, help="output Markdown file")
    args = parser.parse_args()

    rows = read_tsv(args.table)
    quals = [float(r["qual"]) for r in rows if r.get("qual") not in ("", ".")]
    chroms = Counter(r["chrom"] for r in rows)

    lines = [
        "# VCF annotation summary",
        "",
        f"- Variants after filtering: **{len(rows)}**",
        (f"- Mean quality (QUAL): **{sum(quals) / len(quals):.1f}**"
         if quals else "- Mean quality (QUAL): n/a"),
        f"- Chromosomes represented: **{len(chroms)}**",
        "",
        "## Variants per chromosome",
        "",
        "| Chromosome | Variants |",
        "|---|---:|",
    ]
    lines += [f"| {c} | {n} |" for c, n in chroms.most_common()]

    if args.vep:
        vep_rows = read_tsv(args.vep)
        lines += [
            "",
            "## Annotation",
            "",
            f"- VEP annotated records: **{len(vep_rows)}**",
        ]

    lines += [
        "",
        "## First 10 variants",
        "",
        "| Chrom | Pos | Ref | Alt | Qual |",
        "|---|---|---|---|---|",
    ]
    lines += [
        f"| {r['chrom']} | {r['pos']} | {r['ref']} | {r['alt']} | {r['qual']} |"
        for r in rows[:10]
    ]

    Path(args.out).write_text("\n".join(lines) + "\n")
    print(f"Wrote {args.out}")


if __name__ == "__main__":
    main()
