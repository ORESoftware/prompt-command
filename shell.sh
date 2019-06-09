#!/usr/bin/env bash

all_interos_export="yep";

if [[ ! "$SHELLOPTS" =~ "allexport" ]]; then
    all_interos_export="nope";
    set -a;  # we export every declared function using this flag
fi


actual_dir="$(cd $(dirname "$BASH_SOURCE") && pwd)"
. "$actual_dir/locking.sh"

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

clean_str_to_json(){

    local prev='';
    local result='';
    local back_slash='\'
    local bad_str="$1";
    local token='';

    for i in $(seq 1 "${#bad_str}"); do

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

    echo "$result";

}




export previous_cmd="";

run_bash_history(){

    export shell_count=1

    local pid="$1"
    local ec="${2:-'unknown'}"

    read skip rest < <(history 1 );  # first token skipped, remainder stored in variable called rest

    local hist="$(echo "$rest" | filter_my_bsh_history)"

    if [[ -z "$hist" ]]; then
        return;
    fi

    if [[ "$previous_cmd" == "$hist" ]]; then
        return;
    fi

    ql_acquire_lock bash_hist --skip

    export previous_cmd="$hist"

#    data="$( jq -nc --arg str "$hist" '{"attr":$str}' )"
#    hist="$(echo "$data" | jq '.attr')"

    local clean_hist="$(clean_str_to_json "$hist")"

#    hist="$(echo "$hist" | jq -r -R)"  # clean hist

    json="$(cat <<EOF
{"user":"$USER","num":"$skip","time":"$(date)","pwd":"$previous_pwd","pid":$pid,"exit_code":$ec,"cmd":"$clean_hist"}
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

   ql_release_lock bash_hist --skip

}



remove_old_history(){

#  curr_date="$(date -v-1d +%F)"

  local curr_date="$(date)"

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

export shell_count=1

read_up_line_from_bash_history(){
 export shell_count=$((shell_count++))
 cat < <(tail -n "$shell_count" ~/my_bash_history |  head -n 1)
}

read_down_line_from_bash_history(){
 export shell_count=$((shell_count--))
 cat < <(tail -n "$shell_count" ~/my_bash_history |  head -n 1 )
}

bind -x '"\C-o": read_up_line_from_bash_history'
bind -x '"\C-p": read_down_line_from_bash_history'

if [[ "$all_interos_export" == "nope" ]]; then
  set +a;
fi