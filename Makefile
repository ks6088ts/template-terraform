# Git
GIT_REVISION ?= $(shell git rev-parse --short HEAD)
GIT_TAG ?= $(shell git describe --tags --abbrev=0 | sed -e s/v//g)

# Azure
APPLICATION_ID ?= $(shell az ad sp list --display-name $(APPLICATION_NAME) --query "[0].appId" --output tsv)
APPLICATION_NAME ?= "template-terraform_dev"
SUBSCRIPTION_ID ?= $(shell az account show --query id --output tsv)
SUBSCRIPTION_NAME ?= $(shell az account show --query name --output tsv)
TENANT_ID ?= $(shell az account show --query tenantId --output tsv)

# azurerm provider (v4+) requires the subscription ID to be specified explicitly.
# Export it so all Terraform targets pick it up automatically.
export ARM_SUBSCRIPTION_ID ?= $(SUBSCRIPTION_ID)

# Terraform
SCENARIO ?= hello_world
SCENARIO_DIR ?= infra/scenarios/$(SCENARIO)
SCENARIO_DIR_LIST ?= $(shell find infra/scenarios -maxdepth 1 -mindepth 1 -type d -print)
TERRAFORM ?= terraform -chdir="$(SCENARIO_DIR)"
TERRAFORM_LOCK_FILE_LIST ?= $(shell git ls-files 'infra/**/.terraform.lock.hcl')
TERRAFORM_ROOT_DIR_LIST ?= $(sort $(patsubst %/,%,$(dir $(TERRAFORM_LOCK_FILE_LIST))))

# Infracost
INFRACOST_ARGS ?=
# Scan the whole repository unless a scenario is given on the command line.
INFRACOST_PATH ?= $(if $(filter command line,$(origin SCENARIO)),$(SCENARIO_DIR),.)

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
.DEFAULT_GOAL := help

.PHONY: info
info: info-azure ## show information

.PHONY: info-azure
info-azure: ## show information about Azure
	@echo "SUBSCRIPTION_ID: $(SUBSCRIPTION_ID)"
	@echo "SUBSCRIPTION_NAME: $(SUBSCRIPTION_NAME)"
	@echo "TENANT_ID: $(TENANT_ID)"
	@echo "GIT_REVISION: $(GIT_REVISION)"
	@echo "GIT_TAG: $(GIT_TAG)"

.PHONY: install-deps-dev
install-deps-dev: ## install dependencies for development
	@missing=0; \
	for tool in terraform tfupdate curl jq az gh tflint trivy infracost actionlint; do \
		if ! command -v "$$tool" >/dev/null 2>&1; then \
			echo "$$tool is not installed."; \
			missing=1; \
		fi; \
	done; \
	if [ "$$missing" -ne 0 ]; then \
		echo "Install the missing development tools and try again."; \
		exit 1; \
	fi

.PHONY: clean
clean:
	cd $(SCENARIO_DIR) && rm -rf .terraform

.PHONY: init
init:
	$(TERRAFORM) init -lockfile=readonly

.PHONY: update
update: ## update provider constraints and lock files within current majors, then validate
	@sh scripts/update_providers.sh $(TERRAFORM_LOCK_FILE_LIST)
	@set -e; \
	terraform_data_root=$$(mktemp -d); \
	trap 'find "$$terraform_data_root" -depth -delete' 0; \
	for dir in $(TERRAFORM_ROOT_DIR_LIST); do \
		echo "Updating Terraform providers: $$dir"; \
		terraform_data_dir="$$terraform_data_root/$$(printf '%s' "$$dir" | tr '/' '_')"; \
		TF_DATA_DIR="$$terraform_data_dir" terraform -chdir="$$dir" init -backend=false -upgrade -input=false; \
		TF_DATA_DIR="$$terraform_data_dir" terraform -chdir="$$dir" validate; \
	done

.PHONY: lint
lint:
	$(TERRAFORM) fmt -check
	$(TERRAFORM) validate

.PHONY: tflint
tflint:
	@command -v tflint >/dev/null 2>&1 || { echo "tflint is not installed."; exit 1; }
	@echo "Running tflint..."
	@tflint --init
	@tflint --recursive

.PHONY: trivy
trivy:
	@command -v trivy >/dev/null 2>&1 || { echo "trivy is not installed."; exit 1; }
	@echo "Running trivy..."
	@trivy config .

.PHONY: actionlint
actionlint:
	@command -v actionlint >/dev/null 2>&1 || { echo "actionlint is not installed."; exit 1; }
	@echo "Running actionlint..."
	@actionlint

.PHONY: fix
fix: ## fix formatting
	$(TERRAFORM) fmt -recursive

.PHONY: plan
plan:
	$(TERRAFORM) plan

.PHONY: cost
cost: ## estimate monthly cost with Infracost
	infracost scan $(INFRACOST_PATH) $(INFRACOST_ARGS)
	@if [ "$(INFRACOST_PATH)" = "." ]; then \
		echo; \
		echo "Cost per scenario:"; \
		infracost inspect . --group-by project; \
	fi

.PHONY: test
test: init ## test codes
	$(TERRAFORM) test

.PHONY: _ci-test-base
_ci-test-base: clean init lint test plan

.PHONY: ci-test
ci-test: tflint trivy actionlint ## ci test
	@for dir in $(SCENARIO_DIR_LIST) ; do \
		echo "Test: $$dir" ; \
		make _ci-test-base SCENARIO=$$(basename $$dir) || exit 1 ; \
	done

.PHONY: deploy
deploy: init ## deploy resources
	$(TERRAFORM) apply -auto-approve

.PHONY: destroy
destroy: init ## destroy resources
	$(TERRAFORM) destroy -auto-approve

.PHONY: output
output: ## show output values
	@$(TERRAFORM) output
