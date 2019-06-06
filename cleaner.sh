#!/usr/bin/env bash

#foo="$(echo ' bad \"  string"' | sed 's/[^\]"/\\"/g')"


#foo=$(echo ' bad "  string"'  | while read -r -n1 char; do
# :
# done;
#)

prev='';
result='';
back_slash='\'

bad_str=' bad \\\" \n string"';

for i in $(seq 1 ${#bad_str}); do

   token="${bad_str:i-1:1}"

   if [[ "$token" != '"' ]]; then
     result+="$token";
     prev="$token"
     continue;
   fi

   if [[ "$prev" == '\' ]]; then
     result+="$token";
     prev="$token"
     continue;
   fi

   result+="${back_slash}${token}";
   prev="$token"

done;

echo "result: $result"

echo "{\"bar\":\"$result\"}" | jq