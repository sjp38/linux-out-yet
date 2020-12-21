#!/bin/bash

function pr_usage() {
	echo "Usage: $0 [OPTION]... <version>"
	echo
	echo "OPTION"
	echo "  --repo <path>	Specify local repository"
	echo "  -h, --help	Show this message"
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
