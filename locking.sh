#!/usr/bin/env bash


all_interos_export="yep";

if [[ ! "$SHELLOPTS" =~ "allexport" ]]; then
    all_interos_export="nope";
    set -a;  # we export every declared function using this flag
fi

export all_locks="$HOME/.locking/ql/locks";
mkdir -p "$all_locks";


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
        echo 'Acquired lock on first attempt.';
        return 0;
    }

    while true; do
        echo 'Waiting for lock to be released.' > /dev/stderr;
        local val="$(cat "$fifo")"
        if test "$val" == "unlocked"; then
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
   /Users/alex/codes/ores/prompt-command/fcntl "$1"
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