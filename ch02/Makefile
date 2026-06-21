.PHONY: help init fmt validate plan apply destroy destroy-all lint ssh

.DEFAULT_GOAL := help
TF := mise exec -- terraform
TFLINT := mise exec -- tflint
TRIVY := mise exec -- trivy
AZ := mise exec -- az
SSH_KEY ?= ~/.ssh/id_ed25519

help: ## 利用可能なターゲットを表示
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

init: ## terraform init を実行
	$(TF) init

fmt: ## Terraform 設定をフォーマット
	$(TF) fmt

validate: ## Terraform 設定を検証
	$(TF) validate

lint: ## tflint と trivy で静的解析・脆弱性スキャンを実行
	$(TFLINT) --init
	$(TFLINT) --recursive --config=.tflint.hcl
	$(TRIVY) config --severity HIGH,CRITICAL .

ssh: ## Azure Bastion 経由で VM に SSH 接続（SSH_KEY を上書き可能）
	$(AZ) network bastion ssh \
		--name "$$($(TF) output -raw bastion_name)" \
		--resource-group "$$($(TF) output -raw resource_group_name)" \
		--target-resource-id "$$($(TF) output -raw vm_id)" \
		--auth-type ssh-key \
		--username "$$($(TF) output -raw admin_username)" \
		--ssh-key "$(SSH_KEY)"

plan: ## 実行計画を表示
	$(TF) plan

apply: ## リソースを作成/更新
	$(TF) apply

destroy: ## 有料リソースのみを安全に削除（RG/VNet/subnet/NSG は保持）
	$(TF) destroy \
		-target=azurerm_linux_virtual_machine.this \
		-target=azurerm_network_interface.vm \
		-target=azurerm_bastion_host.this \
		-target=azurerm_public_ip.bastion \
		-target=azurerm_public_ip.nat \
		-target=azurerm_nat_gateway.this \
		-target=azurerm_nat_gateway_public_ip_association.this \
		-target=azurerm_subnet_nat_gateway_association.vm

destroy-all: ## すべてのリソースを削除
	$(TF) destroy
