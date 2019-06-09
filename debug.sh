#!/usr/bin/env bash

all_interos_export="yep";

if [[ ! "$SHELLOPTS" =~ "allexport" ]]; then
    all_interos_export="nope";
    set -a;  # we export every declared function using this flag
fi

export all_locks="$HOME/.locking/ql/locks";
mkdir -p "$all_locks";

export all_counts="$HOME/.locking/counts";
mkdir -p "$all_locks";

ql_remove_all_locks(){
  rm -rf "$all_locks"
  mkdir -p "$all_locks";
}

ql_remove_all_counts(){
  rm -rf "$all_counts"
  mkdir -p "$all_counts";
}

if [[ "$all_interos_export" == "nope" ]]; then
  set +a;
fi