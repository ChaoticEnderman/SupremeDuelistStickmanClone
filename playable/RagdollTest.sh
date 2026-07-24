#!/bin/sh
printf '\033c\033]0;%s\a' StickmanDuelOnline
base_path="$(dirname "$(realpath "$0")")"
"$base_path/RagdollTest.x86_64" "$@"
