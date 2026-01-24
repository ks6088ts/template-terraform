# How to use scenarios

## with GNU Make

```shell
# Help
make

# set scenario
SCENARIO=hello_world

# set variables
export ARM_SUBSCRIPTION_ID=$(az account show --query id --output tsv)

# deploy resources
make deploy SCENARIO=$SCENARIO

# destroy resources
make destroy SCENARIO=$SCENARIO
```
