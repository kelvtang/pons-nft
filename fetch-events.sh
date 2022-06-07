#!/bin/bash

__path__="$(dirname "$0")"

# first 3 arguments need to be string while the last one has to be a number
# arugment order is contract_address, contract_name, event_type, last read block

#echo '{ "events": [ { "contract_address": "1", "contract_name": "1", "event_type": "3", "data": "4"} ] }' \
node "$__path__/fetch-events.mjs" "$1" "$2" "$3" "$4" \
| jq -r '(.events[0] | keys_unsorted), (.events[] | to_entries | map(.value))|@csv'
