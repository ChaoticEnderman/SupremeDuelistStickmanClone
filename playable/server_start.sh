#!/bin/bash
redirect="/dev/null"
oneredirect="/dev/null"
goredirect="/dev/null"

truncate -s 0 latest.log
truncate -s 0 one.log

for arg in "$@"; do
	if [[ "$arg" == "-v" ]]; then
		oneredirect="one.log"
		redirect="latest.log"
	fi
	if [[ "$arg" == "-vg" ]]; then
		goredirect="go.log"
	fi
	if [[ "$arg" == "-c" ]]; then
		killall RagdollTest.x86_64
		killall matchmakingserver
		exit 0
	fi
done

go run matchmakingserver.go >> "goredirect" 2>&1 &

start_port=56001
end_port=56004

./RagdollTest.x86_64 -s --headless -p=56000 -r=AS -m=desolation >> "$oneredirect" 2>&1 &
for port in $(seq "$start_port" "$end_port"); do
    ./RagdollTest.x86_64 -s --headless -p="$port" -r=AS -m=rebirth >> "$redirect" 2>&1 &
done


