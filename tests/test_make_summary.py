"""Unit tests for the only custom script in this workflow."""

import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "workflow" / "scripts" / "make_summary.py"

TABLE = (
    "chrom\tpos\tref\talt\tqual\tfilter\tdp\taf\n"
    "chr1\t100\tA\tG\t50\tPASS\t30\t0.4\n"
    "chr2\t200\tC\tT\t30\tPASS\t20\t0.1\n"
)


def run(tmp_path, *extra):
    table = tmp_path / "variants.tsv"
    table.write_text(TABLE)
    out = tmp_path / "summary.md"
    subprocess.run(
        [sys.executable, str(SCRIPT), "--table", str(table), "--out", str(out), *extra],
        check=True,
    )
    return out.read_text()


def test_variant_count_and_mean_quality(tmp_path):
    text = run(tmp_path)
    assert "Variants after filtering: **2**" in text
    assert "Mean quality (QUAL): **40.0**" in text


def test_per_chromosome_table(tmp_path):
    text = run(tmp_path)
    assert "| chr1 | 1 |" in text
    assert "| chr2 | 1 |" in text


def test_vep_section_is_optional(tmp_path):
    vep = tmp_path / "vep.tsv"
    vep.write_text("Uploaded_variation\tGene\nrs1\tTP53\n")
    assert "VEP annotated records" not in run(tmp_path)
    assert "VEP annotated records: **1**" in run(tmp_path, "--vep", str(vep))
