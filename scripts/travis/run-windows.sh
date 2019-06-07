#!/usr/bin/env bash

C:\wget\wget.exe --version

Invoke-WebRequest https://nodejs.org/download/release/latest/node-v12.4.0-win-x64.zip -o 'C:\my_nodejs_download'

mv 'C:\my_nodejs_download' 'C:\Program Files\nodejs'