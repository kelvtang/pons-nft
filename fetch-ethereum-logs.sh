#!/bin/bash

__path__="$(dirname "$0")"
 
node "${__path__}/fetch-ethereum-logs.mjs" "$1" "$2" \
| jq -r '(.logs[0] | keys_unsorted), (.logs[] | to_entries | map(.value))|@csv'