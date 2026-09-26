#!/usr/bin/env bash
# Auton — remaining work reporter + stopper. Does not seal. Does not invent Forge.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "plane=api"
echo "forge_class=none"
echo "done=intent,draw,eval,read,list,seal[n],verify,budgets,reseal-guard,sim-mouth"
echo "blocked.forge=needs /dev/ttyACM0 or /dev/ttyUSB0 beside this host"
echo "blocked.second_keel=do not merge books; pick one writer"
echo "blocked.physics=smith stage 3; metal only"
echo "rule=auton will not wrap, will not seal, will not write SEAL"
if [[ -e /dev/ttyACM0 || -e /dev/ttyUSB0 ]]; then
  echo "device=present — run $ROOT/smith/smith.sh probe"
else
  echo "device=none — stop"
fi
