#!/usr/bin/env bash

user_input="$'a e""R<*&\04\n\thello!\''"

#clean_output="$(jq -nc --arg str "$user_input" '$str')"
#echo "clean output: $clean_output"

clean_output="$(echo "$user_input" | jq -R)"

echo "{\"foo\":$clean_output}" | jq


