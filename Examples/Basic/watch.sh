#!/bin/bash
set -e

./build-dev.sh debug
watchexec -w Sources -e .swift -r './build-dev.sh debug' &
browser-sync start -s -w --ss Public --cwd Public