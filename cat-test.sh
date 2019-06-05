#!/usr/bin/env bash

fif="foooz"; rm "$fif" ; mkfifo "$fif"

( cat "$fif" | cat && echo "1") &

sleep 0.1

( cat "$fif" | cat && echo "2") &

sleep 0.1

( cat "$fif" | cat && echo "3") &

echo "first" > "$fif"

wait;