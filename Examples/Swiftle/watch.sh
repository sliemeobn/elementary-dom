#!/usr/bin/env bash
./build-dev.sh
watchexec -w Sources -e .swift -r './build-dev.sh' &
browser-sync start -s -w --ss Public --cwd Public