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

increment_lock_count(){

  local lock_dir="$HOME/.locking/counts/$1";
  local lock_name="home_locking_counts_$1"

  local lock_name="xxxxx";

#  echo "increment: $lock_name" &> /dev/stderr

  ql_acquire_lock "$lock_name"  --skip &> /dev/stderr

   touch "$lock_dir"
   my_str=$(cat "$lock_dir");
   typeset -i my_num="${my_str:-"0"}"
   echo "$((++my_num))" | tee "$lock_dir"

  ql_release_lock "$lock_name"  --skip  &> /dev/stderr

}


decrement_lock_count(){

  local lock_dir="$HOME/.locking/counts/$1";
  local lock_name="home_locking_counts_$1";

   local lock_name="xxxxx";
#   echo "decrement: $lock_name" &> /dev/stderr

  ql_acquire_lock "$lock_name"  --skip &> /dev/stderr

   touch "$lock_dir"
   my_str="$(cat "$lock_dir")";
   typeset -i my_num="${my_str:-"1"}"
   echo "$((--my_num))" | tee "$lock_dir"

  ql_release_lock "$lock_name" --skip &> /dev/stderr

}

ql_list(){
  mkdir -p "$all_locks";
  find "$all_locks" -mindepth 1 -maxdepth 1 -type d  -printf '%P\n' | sort
}

ql_ls(){
  ql_list "$@"
}

conditionally_exit_with_code(){
  if true; then
    return 0;
  fi

  if [[ ! -t 1 ]] ; then
     exit "$1"
  fi
}

get_appropriate_return_code(){
  if true; then
    echo '0'
    return 0;
  fi
}


ql_on_finish() {

  local current_pid="$$";

  echo "first $1, second: $2" &> /dev/stderr
  echo "the current pid: $current_pid" &> /dev/stderr

  mkdir -p "$all_locks"

  find "$all_locks" -mindepth 1 -maxdepth 1 -type d | while read pth; do

  ls "$pth" &> /dev/stderr

  lock_pid="$(cat "$pth/pid.json")"

  echo "pth: $pth, lock pid: $lock_pid" &> /dev/stderr

  if [[ "$lock_pid" == "$current_pid" ]]; then
    ql_release_lock "$(basename "$pth")"
    return 0;
  fi

  for p in "$(pgrep -P "$$")"; do
    if [[ "$p" == "$current_pid" ]]; then
        ql_release_lock "$(basename "$pth")"
        return 0;
    fi
  done;

  done;
}


add_my_trap(){
    trap ql_on_finish EXIT SIGTERM SIGINT INT TERM SIGCHLD # SIGUSR1 SIGUSR2
}

add_my_trap

ql_acquire_lock(){

    local is_skip="$2"

    if [[ -z "$1" ]]; then
        echo "First argument (the lock-name) must be defined.";
        conditionally_exit_with_code 1;
        return 1;
    fi

    if [[   "${1// }" != "$1" ]]; then
        echo "First argument (the lock-name) cannot contain white-space.";
        conditionally_exit_with_code 1;
        return 1;
    fi

    local lock_name="$(sanitize_lock_name "$1")";

     if [[ -z "$lock_name" ]]; then
        echo "lock name was empty after sanitizing unacceptable characters: '$1'";
        conditionally_exit_with_code 1;
        return 1;
    fi

    local lock_dir="$all_locks/$lock_name"
    local fifo="$lock_dir/fifo.lock";

    mkdir "$lock_dir" &> /dev/null && {

        mkfifo "$fifo"

        echo "$$" > "$lock_dir/pid.json"

       if [[ "--skip" != "$is_skip" ]]; then
            count=`increment_lock_count "$lock_name"`

            if [[ "$count" -ne '1' ]]; then
              echo 'Warning: Lock count was not equal to 1 after lock acquisition.';
            fi
        fi

        [[ "$is_skip" != "--skip" ]] && echo 'Acquired lock on first attempt.';
        conditionally_exit_with_code 0;
        return 0;

    } || {
       echo 'Could not acquire lock on first attempt.';
    }

    while true; do

        echo "Waiting for lock ('$lock_name') to be released." > /dev/stderr;

        local val="$(cat "$fifo")"

        if test "$val" == "unlocked"; then

          if [[ "--skip" != "$is_skip" ]]; then

              count=`decrement_lock_count "$lock_name"`

                if [[ "$count" -ne '0' ]]; then
                  echo 'Lock count was not equal to 0 after lock release.';
                fi
           fi

          [[ "$is_skip" != "--skip" ]] && echo 'Acquired lock.';
          break;
        fi
    done;

}

# https://stackoverflow.com/questions/42075387/check-whether-named-pipe-fifo-is-open-for-writing


is_named_pipe_already_opened0(){
 echo '' 1<>"$1" >"$1"
}

is_named_pipe_being_read() {
   if test "$(uname -s)" == 'Darwin'; then
        /Users/alex/codes/ores/prompt-command/fcntl_mac "$1"
   else
        /home/oleg/codes/oresoftware/prompt-command/fcntl "$1"
   fi
}

ql_release_lock(){

    local is_skip="$2"

    if [[ -z "$1" ]]; then
        echo "First argument (lock name) must be defined.";
        conditionally_exit_with_code 1;
        return 1;
    fi

    if [[ "${1// }" != "$1" ]]; then
        echo "First argument (the lock-name) cannot contain white-space.";
        conditionally_exit_with_code 1;
        return 1;
    fi

    local lock_name="$(sanitize_lock_name "$1")";

    local lock_dir="$all_locks/$lock_name"

    if [[ ! -d "$lock_dir" ]]; then
      conditionally_exit_with_code 1;
      return 1;
    fi

     if [[ ! -f "$lock_dir/pid.json" ]]; then
      echo 'There should be a pid.json file in the dir.' > /dev/stderr
      conditionally_exit_with_code 1
      return 1;
    fi


    local fifo="$lock_dir/fifo.lock";

    if [[ ! -p "$fifo" ]]; then
      echo 'There should be a fifo.lock file in the dir.' > /dev/stderr
      return 0;
    fi

    # https://unix.stackexchange.com/questions/522877/how-to-cat-named-pipe-without-waiting/522881

     if [[ "--skip" != "$is_skip" ]]; then

        count=`decrement_lock_count "$lock_name"`

        if [[ "$count" -ne '0' ]]; then
          echo 'Lock count was not equal to 0 after unlocking.'
        fi

    fi

   if  is_named_pipe_being_read "$fifo"; then
        echo "unlocked" > "$fifo"
   else
       rm -rf "$lock_dir" | cat
       [[ "$is_skip" != "--skip" ]] && echo "Lock deleted."
   fi

   echo -n '';
}


if [[ "$all_interos_export" == "nope" ]]; then
  set +a;
fi