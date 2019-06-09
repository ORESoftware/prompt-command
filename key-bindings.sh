#!/usr/bin/env bash

#(
#
#   sigttin_catcher(){
#    echo "sigttin $1 $2 $3"
#   }
#
#   export -f sigttin_catcher;
#
#   trap  sigttin_catcher SIGTTIN;
#
#  set +e;
#    while true; do
#        while read -s -n 1 c; do
#          echo "char: $c"
#        done
#    done
#) &


#run_foo(){
#  echo 'here is poo'
#  ^[[5A
#}
#
#export -f run_foo

bind -x '"\C-o": echo '
