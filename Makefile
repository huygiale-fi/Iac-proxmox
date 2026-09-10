.PHONY: check-api init validate plan apply inventory configure api-list destroy

check-api:
	./scripts/check-proxmox-api.sh

init:
	terraform -chdir=terraform init

validate:
	terraform -chdir=terraform fmt -check -recursive
	terraform -chdir=terraform validate
	ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i localhost, --syntax-check ansible/site.yml

plan:
	terraform -chdir=terraform plan -out=demo.tfplan

apply:
	terraform -chdir=terraform apply demo.tfplan

inventory:
	./scripts/render-inventory.sh

configure: inventory
	ANSIBLE_CONFIG=ansible/ansible.cfg ansible-playbook -i ansible/inventory.ini ansible/site.yml

api-list:
	./scripts/proxmox-api.sh list

destroy:
	terraform -chdir=terraform destroy
