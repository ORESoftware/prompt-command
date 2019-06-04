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

  rm -rf "$all_locks/$1"
}

 # apt-get install socat

ql_acquire_lock(){

    if [[ -z "$1" ]]; then
        echo "First argument must be defined.";
        return 1;
    fi

    local lock_dir="$all_locks/$1"
    local fifo="$lock_dir/fifo.lock";
    local socket="$lock_dir/uds.sock";

    mkdir "$lock_dir" &> /dev/null && {
        mkfifo "$fifo"
        touch "$socket"
        echo "$$" > "$lock_dir/pid.json"
        echo 'Acquired lock on first attempt.';
        return 0;
    }

    while true; do
        echo 'Waiting for lock to be released.';
        local val="$(cat "$fifo")"
        if test "$val" == "unlocked"; then
          echo 'Acquired lock.';
          break;
        else
         echo "Message was: $val";
        fi
    done;

#    while true; do
#        echo 'Waiting for lock to be released.';
##        local val="$(cat "$fifo")"
#        result=$(nc -l -U "$socket" | read val; if test "$val" == "unlocked"; then
#             echo "ready";
#        fi);
#
#        if test "$result" == "ready"; then
#          break;
#        fi
#    done;
#
#    ql_acquire_lock "$@"
}

# https://stackoverflow.com/questions/42075387/check-whether-named-pipe-fifo-is-open-for-writing

is_named_pipe_already_opened() {

    local named_pipe="$1"
    # Make sure it's a named pipe
    if ! [[ -p "$named_pipe" ]]; then
        echo "Named pipe does not exist $named_pipe";
        return 1
    fi
    # Try to write zero bytes in the background
    ( (echo "unlocked" > "$named_pipe" )  & ) &>/dev/null
    pid="$!"
    # Wait a short amount of time
    sleep 0.25
    # Kill the background process. If kill succeeds, then
    # the write was blocked indicating that someone
    # else is already writing to the named pipe.
    ( kill -PIPE "$pid" ) &> /dev/null
}

ql_release_lock(){

    if [[ -z "$1" ]]; then
        echo "First argument must be defined.";
        return 1;
    fi

    local lock_dir="$all_locks/$1"


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

    echo "About to release lock with key: $1"
    echo "Writing unlocked to fifo...";

#    ( cat "$fifo" ) &
#    wait $!

#     ls "$fifo"

#    echo 'test' | dd flag='nonblock' of="$fifo" status=none || {
#       rm -rf "$lock_dir"
#       echo "Lock deleted."
#       return 0;
#    }

#    val="$(echo "unlocked" > "$fifo" > >(read line; echo "$line"))";

#    val=$(cat "$fifo" < <(echo "unlocked"));

#    val="$(read line; echo "$line") > "$fifo" > >()";
#    echo "val: $val"

#    local socket="$lock_dir/uds.sock";
#
#    echo "unlocked" | nc -U "$socket"

#    echo "unlocked" > "$fifo"

    # https://unix.stackexchange.com/questions/522877/how-to-cat-named-pipe-without-waiting/522881


   if is_named_pipe_already_opened "$fifo"; then
       rm -rf "$lock_dir"
       echo "Lock deleted."
   fi


#    local val="$(cat 0<> "$fifo" < "$fifo" < <(echo "locked"; echo "unlocked"))"
##    local val="$(cat < "$fifo" < <(echo "unlocked"))"
#
#    echo 'No longer waiting on cat.';
#
#    if test "$val" == 'unlocked'; then
#       rm -rf "$lock_dir"
#       echo "Lock deleted."
#    fi

}




if [[ "$all_interos_export" == "nope" ]]; then
  set +a;
fi