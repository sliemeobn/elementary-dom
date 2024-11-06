#!/usr/bin/env bash
./build.sh
watchexec -w Sources -e .swift -r './build.sh' &
browser-sync start -s -w --ss Public --cwd Public