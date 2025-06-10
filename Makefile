OPENSHIFT := $(shell which oc)
TERRAFORM := $(shell which terraform)
ARGOCD_URL := $(shell sops decrypt secrets/secrets.yaml | grep argocd_url | cut -d ' ' -f 2)
OPENSHIFT_API_URL := $(shell sops decrypt secrets/secrets.yaml | grep cluster_host | cut -d ' ' -f 2)
OPENSHIFT_TF_NAMESPACE := $(shell sops decrypt secrets/secrets.yaml | grep tf_namespace | cut -d ' ' -f 2)
CONTEXT := $(shell ${OPENSHIFT} config current-context 2>/dev/null)
DESIRED_CONTEXT := $(shell sops decrypt secrets/secrets.yaml | grep desired_context | cut -d ' ' -f 2)

.PHONY: help init plan apply test pre-commit-check-deps pre-commit-install-hooks argocd-login argocd-sync sync clean

help:
	@echo "General targets"
	@echo "----------------"
	@echo
	@echo "\thelp: show this help text"
	@echo "\tclean: removes all .terraform directories"
	@echo
	@echo "Terraform targets"
	@echo "-----------------"
	@echo
	@echo "\tinit: run 'terraform init'"
	@echo "\ttest: run pre-commmit checks"
	@echo "\tplan: run 'terraform plan'"
	@echo "\tapply: run 'terraform apply'"
	@echo
	@echo "One-time repo init targets"
	@echo "--------------------------"
	@echo
	@echo "\tpre-commit-install-hooks: install pre-commit hooks"
	@echo "\tpre-commit-check-deps: check pre-commit dependencies"
	@echo

clean:
	@find . -name .terraform -type d | xargs -I {} rm -rf {}

init: check-context clean .terraform/terraform.tfstate

.terraform/terraform.tfstate:
	@${OPENSHIFT} get project ${OPENSHIFT_TF_NAMESPACE} > /dev/null 2>&1 || ${OPENSHIFT} new-project ${OPENSHIFT_TF_NAMESPACE}
	@${TERRAFORM} init -reconfigure -upgrade -input=false -backend-config="host=https://${OPENSHIFT_API_URL}" -backend-config="namespace=${OPENSHIFT_TF_NAMESPACE}"

plan: init .terraform/plan

.terraform/plan:
	@${TERRAFORM} state show kubernetes_manifest.openshift_gitops_subscription >/dev/null 2>&1 && ${TERRAFORM} plan -compact-warnings -out .terraform/plan || ${TERRAFORM} plan -compact-warnings -out .terraform/plan -target kubernetes_manifest.openshift_gitops_subscription

apply: test plan
	@${TERRAFORM} state show kubernetes_manifest.openshift_gitops_subscription >/dev/null 2>&1 || ( echo "INITIAL DEPLOYMENT" && ${TERRAFORM} apply -auto-approve -compact-warnings -target kubernetes_manifest.openshift_gitops_subscription .terraform/plan && rm -f .terraform/plan && echo "SLEEPING FOR 30 SECONDS FOR GITOPS DEPLOYMENT" && sleep 30 && oc apply -k kustomize && ${TERRAFORM} plan -compact-warnings -out .terraform/plan )
	@${TERRAFORM} apply -auto-approve -compact-warnings .terraform/plan
	@rm -f .terraform/plan

test: check-context .git/hooks/pre-commit
	@pre-commit run -a

DEPS_PRE_COMMIT=$(shell which pre-commit || echo "pre-commit not found")
DEPS_TERRAFORM_DOCS=$(shell which terraform-docs || echo "terraform-docs not found")
DEPS_TFLINT=$(shell which tflint || echo "tflint not found,")
DEPS_TFSEC=$(shell which tfsec || echo "tfsec not found,")
DEPS_CHECKOV=$(shell which checkov || echo "checkov not found,")
DEPS_INFRACOST=$(shell which infracost || echo "infracost not found,")
DEPS_TFUPDATE=$(shell which tfupdate || echo "tfupdate not found,")
DEPS_HCLEDIT=$(shell which hcledit || echo "hcledit not found,")
DEPS_JQ=$(shell which jq || echo "jq not found,")
DEPS_YQ=$(shell which yq || echo "yq not found,")
pre-commit-check-deps:
	@echo "Checking for pre-commit and its dependencies:"
	@echo "  pre-commit: ${DEPS_PRE_COMMIT}"
	@echo "  terraform-docs: ${DEPS_TERRAFORM_DOCS}"
	@echo "  tflint: ${DEPS_TFLINT}"
	@echo "  tfsec: ${DEPS_TFSEC}"
	@echo "  checkov: ${DEPS_CHECKOV}"
	@echo "  infracost: ${DEPS_INFRACOST}"
	@echo "  tfupdate: ${DEPS_TFUPDATE}"
	@echo "  hcledit: ${DEPS_HCLEDIT}"
	@echo "  jq: ${DEPS_JQ}"
	@echo "  yq: ${DEPS_YQ}"
	@echo ""

pre-commit-install-hooks: .git/hooks/pre-commit

.git/hooks/pre-commit: pre-commit-check-deps
	@pre-commit install --install-hooks

check-context:
	@ if [[ "${CONTEXT}" == *"${DESIRED_CONTEXT}"* ]]; then echo "Context check passed"; else echo "Context check failed" && exit 1; fi

argocd-login:
	@ argocd login --skip-test-tls --insecure --username admin --password "$(shell ${OPENSHIFT} get secret openshift-gitops-cluster -n openshift-gitops -o jsonpath='{.data.admin\.password}' | base64 -d)" ${ARGOCD_URL}

argocd-sync: argocd-login
	@ argocd app sync gitops-configs

sync: argocd-sync
