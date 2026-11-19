.PHONY: help setup test dry-run demo run clean

help: ## Show available commands
	@grep -E '^[a-z-]+:.*##' Makefile | sed 's/:.*##/ -- /'

setup: ## Pull container images and show the VEP cache command
	apptainer pull --dir containers $(shell grep 'bcftools:' config/config.yaml | sed 's/.*"\(.*\)"/\1/')
	apptainer pull --dir containers $(shell grep 'vep:' config/config.yaml | sed 's/.*"\(.*\)"/\1/')
	@echo ""
	@echo "VEP also needs a one-time GRCh38 cache:"
	@echo "  vep_install -a cf -s homo_sapiens -y GRCh38 -c ~/vep_cache --CONVERT"

test: ## Unit tests + DAG dry-run
	bash tests/smoke.sh

dry-run: ## Print the workflow DAG without running it
	snakemake -n --use-singularity --cores 1

demo: ## Run without VEP cache (filter + table + summary)
	VCF_ANNOTATE_MODE=skip snakemake --cores 4

run: ## Run the full pipeline
	snakemake --use-singularity --cores 4

clean: ## Delete generated files
	rm -rf results .snakemake
