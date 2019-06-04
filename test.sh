#!/usr/bin/env bash

set -e;

cd `dirname "$BASH_SOURCE"`;

source locking.sh

#ql_release_lock a;
ql_remove_all_locks

ls -a "$HOME/.locking/ql/locks"

ql_acquire_lock a

(  sleep 1; ql_release_lock a; ) &

ql_acquire_lock a;

ql_release_lock a;

echo '111';

ql_acquire_lock a;

echo '222'

ql_release_lock a;

echo '333'

wait;
