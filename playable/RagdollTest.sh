#!/bin/sh
echo -ne '\033c\033]0;RagdollTest\a'
base_path="$(dirname "$(realpath "$0")")"
"$base_path/RagdollTest.x86_64" "$@"
