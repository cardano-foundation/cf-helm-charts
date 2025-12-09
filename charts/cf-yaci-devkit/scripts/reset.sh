#!/bin/bash

kubectl patch statefulset -n cf-lob cf-yaci-devkit --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["/app/yaci-cli", "create-node", "--start", "-o"]}
]'



# kubectl rollout 

kubectl patch statefulset -n cf-lob cf-yaci-devkit --type='json' -p='[
  {"op": "replace", "path": "/spec/template/spec/containers/0/command", "value": ["/app/yaci-cli", "create-node", "--start"]}
]'
