#!/bin/bash
set -e

./build-wasi.sh debug
watchexec -w Sources -e .swift -r './build-wasi.sh debug' &
browser-sync start -s -w --ss Public --cwd Public