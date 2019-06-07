#!/usr/bin/env bash

echo 'this is the travis build running for nodejs version: '"$1"


curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"  # This loads nvm


nvm install "$1"
nvm use "$1"

echo "This is foo: $foo";