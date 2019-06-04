#!/usr/bin/env bash

all_interos_export="yep";

if [[ ! "$SHELLOPTS" =~ "allexport" ]]; then
    all_interos_export="nope";
    set -a;  # we export every declared function using this flag
fi

export previous_pwd="$PWD"

filter_my_bsh_history(){

  while read line; do

   if [[ -z "$line" ]]; then
      echo "";
      continue;
   fi

   if [[ "$line" == '[[:space:]]*cd '* ]]; then
      echo "";
      continue;
   fi

    if [[ "$line" == '[[:space:]]*ls '* ]]; then
      echo "";
      continue;
   fi

   if [[ "$line" == 'cd '* ]]; then
      echo "";
      continue;
   fi

    if [[ "$line" == 'ls '* ]]; then
      echo "";
      continue;
   fi

    echo "$line"

  done;

}


export previous_cmd="";

run_bash_history(){

    local pid="$1"
    local ec="$2"

    read skip rest < <(history 1 );  # first token skipped, remainder stored in variable called rest

    hist="$(echo "$rest" | filter_my_bsh_history)"

    if [[ -z "$hist" ]]; then
        return;
    fi

    if [[ "$previous_cmd" == "$hist" ]]; then
        return;
    fi

    export previous_cmd="$hist"

    json="$(cat <<EOF
{"user":"$USER","num":"$skip","time":"$(date)","pwd":"$previous_pwd","pid":$pid,"exit_code":$ec,"cmd":"$hist"}
EOF
)"

   echo "$json" >> $HOME/my_bash_history;
   export previous_pwd="$PWD";

}



remove_old_history(){

#  curr_date="$(date -v-1d +%F)"

  curr_date="$(date)"

  while read line; do

  d=`echo "$line" | jq -r '.time'`;

  if [[ "$curr_date" > "$d" ]] ; then
       sed '1d' ~/my_bash_history
  fi

  done < ~/my_bash_history

}


read_my_bash_history(){
  cat ~/my_bash_history | jq
}


export PROMPT_COMMAND='run_bash_history $! $?;';


if [[ "$all_interos_export" == "nope" ]]; then
  set +a;
fi