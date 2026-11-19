#!/usr/bin/env bash
# End-to-end check of the one-command wrapper with FORMAT-only DP/AF fields.
# Needs either Apptainer/Singularity or a local `bcftools` on PATH.
set -euo pipefail
cd "$(dirname "$0")/.."

OUT="$(mktemp -d)"
trap 'rm -rf "$OUT"' EXIT

./vcf-annotate -i tests/format_fields.vcf -o "$OUT" --no-annotate > /dev/null

test -f "$OUT/format_fields.filtered.vcf"
test -f "$OUT/format_fields.variants.tsv"
test -f "$OUT/format_fields.summary.md"

ROWS="$(tail -n +2 "$OUT/format_fields.variants.tsv" | wc -l)"
test "$ROWS" -eq 2
grep -q $'chr1\t100\tA\tG\t50\tPASS\t30\t0.5' "$OUT/format_fields.variants.tsv"
grep -q 'Variants after filtering: \*\*2\*\*' "$OUT/format_fields.summary.md"

echo "integration test OK"
