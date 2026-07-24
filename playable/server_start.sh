#!/bin/bash

redirect="/dev/null"

for arg in "$@"; do
	if [[ "$arg" == "--verbose" ]]; then
		redirect="/dev/tty"
	fi
	if [[ "$arg" == "--clean" ]]; then
		killall RagdollTest.x86_64
	fi
done

start_port=56000
end_port=56004

for port in $(seq "$start_port" "$end_port"); do
    ./RagdollTest.x86_64 -s -p="$port" -r=AS > "$redirect" 2>&1 &
done


