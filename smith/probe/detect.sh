#!/usr/bin/env bash
set -euo pipefail
for cand in /dev/ttyACM0 /dev/ttyUSB0; do [[ -e "$cand" ]] && { echo present "$cand"; exit 0; }; done
echo absent; exit 0
