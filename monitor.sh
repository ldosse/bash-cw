#!/usr/bin/env bash
cd "$HOME/.trashCan"


declare -a files1
declare -a files2

md5_f(){
	md5_1=$(md5sum "$1")
	sleep 15

	if [[ -f "$f1" ]]; then
		md5_2=$(md5sum "$1")
		if [ ! "$md5_1" == "$md5_2" ]; then
		echo "$1: was modified"
		fi
	fi
}


changed_files(){
	for f1 in $files1; do

		if [[ ! -f "$f1" ]]; then
		   echo "$f1 was removed from the trashcan."	
		else

		   md5_f "$f1" &
		fi
	done
    
}


find_added_files(){
	tmp1=$(mktemp)
	find . -maxdepth 1 -type f > $tmp1
	sleep 15
	tmp2=$(mktemp)
	find . -maxdepth 1 -type f > $tmp2

	added=$(diff $tmp1 $tmp2 | grep ">" | tr -d ">")
	for i in $added; do
	  echo "$i was added to the trashcan."
	done
}

main(){
	printf "\t\tMonitoring trashcan\n\t\tLina Bennani Dosse - S1719026\n"
	echo "================================================================"

	files1=$(find . -maxdepth 1 -type f)
	while true; do

		files2=$(find . -maxdepth 1 -type f)
		
		changed_files &
		
		find_added_files &
		
		files1=$files2
		
		sleep 15
	done
}

main
