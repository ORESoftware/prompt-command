#!/usr/bin/env bash

set -e;

cd `dirname "$BASH_SOURCE"`;

source locking.sh

ql_remove_all_locks

ls "$HOME/.locking/ql/locks"

echo "hmmm 1"

ql_acquire_lock a

echo "hmmm 111"


(  sleep 1; ql_release_lock a; ) &

echo "hmmm 2"

ql_acquire_lock a || echo 'wuttt'

echo "hmmm 3"

ql_release_lock a;

echo '111';

ql_acquire_lock a;

echo '222'

ql_release_lock a;

echo '333'

wait;
