#!/usr/bin/env bash


mkfifo fooo

echo 'bar' > fooo

echo 'done'