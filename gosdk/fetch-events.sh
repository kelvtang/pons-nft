#!/bin/bash

__path__="$(dirname "$0")"

"${__path__}/gosdk" "$1" "${2:-nil}" \
| jq -r '(.events[0] | keys_unsorted), (.events[] | to_entries | map(.value))|@csv'
