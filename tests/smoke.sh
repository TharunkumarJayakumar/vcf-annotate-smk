#!/usr/bin/env bash
# CI smoke test: unit tests + Snakemake DAG validation (no containers needed).
set -euo pipefail
cd "$(dirname "$0")/.."

python -m pytest tests/test_make_summary.py -q
snakemake -n --use-singularity --cores 1 > /dev/null
echo "smoke test OK"
