#!/bin/bash

__path__="$(dirname "$0")"

"${__path__}/fetch-events" "$1" \
| jq -r '(.events[0] | keys_unsorted), (.events[] | to_entries | map(.value))|@csv' > test.csv
