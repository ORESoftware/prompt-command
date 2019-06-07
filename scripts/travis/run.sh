#!/usr/bin/env bash

echo 'this is the travis build running for nodejs version: '"$1"


curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
