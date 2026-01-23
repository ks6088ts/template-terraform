# How to use scenarios

## with GNU Make

```shell
# Help
make

# set scenario
SCENARIO=hello_world

# deploy resources
make deploy SCENARIO=$SCENARIO

# destroy resources
make destroy SCENARIO=$SCENARIO
```
