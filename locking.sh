#!/usr/bin/env bash


all_interos_export="yep";

if [[ ! "$SHELLOPTS" =~ "allexport" ]]; then
    all_interos_export="nope";
    set -a;  # we export every declared function using this flag
fi

export all_locks="$HOME/.locking/ql/locks";
mkdir -p "$all_locks";

export count_dir="$HOME/.locking/counts"
mkdir -p "$count_dir";


ql_get_latest(){
  . "$BASH_SOURCE";
}

ql_set_timer(){
   sleep "$1"
}

ql_remove_all_locks(){
  rm -rf "$all_locks"
  mkdir -p "$all_locks";
}

ql_rm_lock(){

    if [[ -z "$1" ]]; then
         echo 'No argument passed, no lock can be removed.' > /dev/stderr;
         return 1;
    fi

    local lock_name="$(sanitize_lock_name "$1")";

    if [[ -z "$lock_name" ]]; then
        echo "lock name was empty after sanitizing unacceptable characters: '$1'";
        return 1;
    fi

    rm -rf "$all_locks/$lock_name"
}

 # apt-get install socat

sanitize_lock_name(){
    # echo "$1" | tr '"' '' | sed "s/'//g" | sed s'/[— – -]/_/g'
    echo "$1" | sed s'/[— – -]/_/g'
}

increment_decrement_lock_count(){

 if [[ "$2" != "a" ]]; then
     echo 0;
     return;
 fi;

# if [[ "$(uname -s)" == 'Darwin' ]]; then
#   echo 0;
#   return 0;
# fi

(
flock -x 200

   my_file="$HOME/.locking/counts/counts.json"
   touch "$my_file"
   my_str=$(cat "$my_file");
   typeset -i my_num="${my_str:-"1"}"
   echo "$((my_num=my_num+$1))" | tee "$my_file"

)200>>/var/lock/mylockfile

}


ql_acquire_lock(){

    if [[ -z "$1" ]]; then
        echo "First argument must be defined.";
        return 1;
    fi

    local lock_name="$(sanitize_lock_name "$1")";

     if [[ -z "$lock_name" ]]; then
        echo "lock name was empty after sanitizing unacceptable characters: '$1'";
        return 1;
    fi

    local lock_dir="$all_locks/$lock_name"
    local fifo="$lock_dir/fifo.lock";

    mkdir "$lock_dir" &> /dev/null && {
        mkfifo "$fifo"
        echo "$$" > "$lock_dir/pid.json"
        count=`increment_decrement_lock_count 1 "$lock_name"`

        echo "COUNT 1: $count"

        if [[ "$count" > 1 ]]; then
          echo 'Lock count was greater than 1 after lock acqusition.';
        fi
        echo 'Acquired lock on first attempt.';
        return 0;
    }

    while true; do
        echo 'Waiting for lock to be released.' > /dev/stderr;
        local val="$(cat "$fifo")"
        if test "$val" == "unlocked"; then
          count=`increment_decrement_lock_count 1 "$lock_name"`

        echo "COUNT 2: $count"

        if [[ "$count" > 1 ]]; then
          echo 'Lock count was greater than 1 after lock acqusition.';
        fi
          echo 'Acquired lock.';
          break;
        fi
    done;

}

# https://stackoverflow.com/questions/42075387/check-whether-named-pipe-fifo-is-open-for-writing


is_named_pipe_already_opened0(){
 echo '' 1<>"$1" >"$1"
}

is_named_pipe_being_read() {
   /Users/alex/codes/ores/prompt-command/fcntl_mac "$1"
#/home/oleg/codes/oresoftware/prompt-command/fcntl "$1"
}

ql_release_lock(){

    if [[ -z "$1" ]]; then
        echo "First argument must be defined.";
        return 1;
    fi

    local lock_name="$(sanitize_lock_name "$1")";

    local lock_dir="$all_locks/$lock_name"

    if [[ ! -d "$lock_dir" ]]; then
      return 0;
    fi

     if [[ ! -f "$lock_dir/pid.json" ]]; then
      echo 'There should be a pid.json file in the dir.' > /dev/stderr
      return 0;
    fi


    local fifo="$lock_dir/fifo.lock";

    if [[ ! -p "$fifo" ]]; then
      echo 'There should be a fifo.lock file in the dir.' > /dev/stderr
      return 0;
    fi

    # https://unix.stackexchange.com/questions/522877/how-to-cat-named-pipe-without-waiting/522881


    count=`increment_decrement_lock_count '-1' "$lock_name"`


    if [[ "$count" > 0 ]]; then
      echo 'Lock count was greater than 0.'
    fi

   if  is_named_pipe_being_read "$fifo"; then
        echo "unlocked" > "$fifo"
   else
       rm -rf "$lock_dir"
       echo "Lock deleted."
   fi




}


if [[ "$all_interos_export" == "nope" ]]; then
  set +a;
fi