#!/usr/bin/env bash
cd "$HOME/.trashCan"

#declares 2 arrays
declare -a files1
declare -a files2

#compares files every 15 seconds using md5sum
md5_f(){
	md5_1=$(md5sum "$1")
	sleep 15
	#checks if the file still exists
	if [[ -f "$f1" ]]; then
		md5_2=$(md5sum "$1")
		if [ ! "$md5_1" == "$md5_2" ]; then
		echo "$1: was modified"
		fi
	fi
}

#check for deleted and modified files
changed_files(){
	for f1 in $files1; do
		#checks if file still exists, if not it was deleted
		if [[ ! -f "$f1" ]]; then
		   echo "$f1 was removed from the trashcan."	
		else
		#calls the md5 function in the background
		   md5_f "$f1" &
		fi
	done
    
}


# finds added files
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
	#store listing of files in the trashcan initially. files1 will refer to listing before 15 s
	files1=$(find . -maxdepth 1 -type f)
	while true; do
		#stores current listing of files in the trashcan. files2 will refer to listing after 15 s
		files2=$(find . -maxdepth 1 -type f)
		
		#gets status update of modified files
		changed_files &
		
		#gets status update of new additions
		find_added_files &
		
		# updates current listing; so after 15 seconds of files1	
		files1=$files2
		
		sleep 15
	done
}
#calls the main method
main
