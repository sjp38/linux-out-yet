#!/bin/bash

function pr_usage() {
	echo "Usage: $0 [OPTION]... <base version>"
	echo
	echo "OPTION"
	echo "  --repo <path>	Specify local repository"
	echo "  -h, --help	Show this message"
	echo
	echo "<base version> is, for example, 'v5.' or 'v5.10.'"
	exit 1
}

while [ $# -ne 0 ]
do
	case $1 in
	"--repo")
		if [ $# -lt 2 ]
		then
			echo "<path> not given"
			pr_usage
			exit 1
		fi
		local_repo=$2
		shift 2
		continue
		;;
	"--help" | "-h")
		pr_usage
		exit 0
		;;
	*)
		if [ ! -z "$base_version" ]
		then
			echo "more than one <base_version>"
			pr_usage
			exit 1
		fi
		base_version=$1
		shift 1
		continue
		;;
	esac
done

if [ -z "$base_version" ]
then
	pr_usage
	exit 1
fi

bindir=$(dirname "$0")
is_out="$bindir/linux-out-yet.sh"
if [ ! -z "$local_repo" ]
then
	is_out="$is_out --repo $local_repo"
fi

start=0
# stable versions start from 1
if [ $(echo "$base_version" | awk -F'.' '{print NF}') -eq 3 ]
then
	start=1
fi

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

# Do binary search
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
