#!/usr/bin/env bash

temp_dir="$HOME/temperton/tmp";

mkdir -p "$temp_dir"


#(
#
#  flock -x "$temp_dir/a"
#  echo '111'
#
#) &
#
#(
#
#  flock -x "$temp_dir/a"
#  echo '222'
#
#) &


(
flock -x 200

 echo 'a:111'
 sleep 5
 echo 'a:222'


) 200>"$temp_dir/a" &


#(
#flock -x 200
#
# echo 'b:111'
# sleep 2
# echo 'b:222'
#
#) 200>"$temp_dir/a" &

wait;