#!/bin/sh
# Builds out/reboot-to-linux-ksu.zip, the KernelSU (or Magisk) module.
set -eu
top=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$top/out"
rm -f "$top/out/reboot-to-linux-ksu.zip"
cd "$top/ksu-module"
zip -q -X "$top/out/reboot-to-linux-ksu.zip" module.prop action.sh
ls -l "$top/out/reboot-to-linux-ksu.zip"
