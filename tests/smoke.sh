#!/usr/bin/env bash
# CI smoke test: unit tests + Snakemake DAG validation (no containers needed).
set -euo pipefail
cd "$(dirname "$0")/.."

python -m pytest tests/test_make_summary.py -q
# DAG validation only: container runtime is not required for a dry-run.
snakemake -n --cores 1 > /dev/null
echo "smoke test OK"
