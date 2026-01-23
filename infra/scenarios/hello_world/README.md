# Hello World Scenario

Use random pro

## Prerequisites

- Terraform CLI installed

## How to use

```shell
# Move to the scenario directory
cd infra/scenarios/hello_world

# Create variable definitions file
cat > terraform.tfvars <<EOF
byte_length = 2
EOF

# Initialize Terraform
terraform init

# Plan the deployment
terraform plan -out=tfplan

# Apply the deployment
terraform apply tfplan
# or simply
terraform apply -auto-approve

# Confirm the output
terraform output

# Confirm the state file
cat terraform.tfstate

# Destroy the deployment
terraform destroy -auto-approve
```
