#!/bin/bash

if [ $# -ne 1 ]
then
	echo "Usage: $0 <base version>"
	echo "  e.g., 'v5.' or 'v5.4.' for latest 5.x and 5.4.y kernel."
	exit 1
fi

bindir=$(dirname "$0")
is_out="$bindir/linux-out-yet.sh"
base_version=$1

start=0
if [ $(echo "$base_version" | awk -F'.' '{print NF}') -eq 3 ]
then
	start=1
fi

function is_last_version()
{
	base=$1
	last_version=$2

	version=$base$last_version
	next_version=$base$((last_version + 1))

	if [ $is_out "$version" ] && [ ! $is_out "$next_version" ]
	then
		echo 1
	fi
	echo 0
}

if ! $is_out "$base_version$start" > /dev/null
then
	echo "The series is not released yet"
	exit 1
fi

# Find upperbound
end=2
while :;
do
	if ! $is_out "$base_version$end" > /dev/null
	then
		break
	fi
	end=$((end * 2))
done

start=$((end / 2))
while [ $start -le $end ]
do
	mid=$(( (start + end) / 2 ))
	if ! $is_out "$base_version$mid" > /dev/null
	then
		end=$((mid - 1))
		continue
	fi

	if $is_out "$base_version$((mid + 1))" > /dev/null
	then
		start=$((mid + 1))
		continue
	fi
	echo "$base_version$mid"
	exit 0
done

exit 1
