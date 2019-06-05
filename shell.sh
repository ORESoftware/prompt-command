#!/usr/bin/env bash

all_interos_export="yep";

if [[ ! "$SHELLOPTS" =~ "allexport" ]]; then
    all_interos_export="nope";
    set -a;  # we export every declared function using this flag
fi


. locking.sh

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

    ql_acquire_lock bash_hist

    export previous_cmd="$hist"

    data="$( jq -nc --arg str "$hist" '{"attr": $str}' )"
    echo "data: $data"
    hist="$(echo "$data" | jq -r '.attr')"

    json="$(cat <<EOF
{"user":"$USER","num":"$skip","time":"$(date)","pwd":"$previous_pwd","pid":$pid,"exit_code":$ec,"cmd":"$hist"}
EOF
)"

   echo "$json" >> $HOME/my_bash_history;

   read num_lines rest < <(wc -l "$HOME/my_bash_history")

   if [[ "$num_lines" -gt '3' ]]; then
   :
#       sed '0,1d' "$HOME/my_bash_history" > "$HOME/my_bash_history2"
#       cat "$HOME/my_bash_history2" > "$HOME/my_bash_history"
   fi

   export previous_pwd="$PWD";

   ql_release_lock bash_hist

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