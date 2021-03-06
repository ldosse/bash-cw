#!/usr/bin/env bash
printf "\n	\t\tHi! Welcome to \e[32m SafeDel utility.\e[0m\n\t\t Lina Bennani Dosse - S1719026\n"
printf "\e[32m===========================================================================\e[0m\n"
current=$(pwd)
man -w gnome-terminal > /dev/null
if [[ ! $? -eq 0 ]]; then 
	sudo apt-get install gnome-terminal
fi

trap trapCtrlC SIGINT

# Here we trap when the script ends regardless of the cause
trap trapEndScript EXIT


storageWarning(){
	[[ $(du -s | tr -d ".") -gt 1 ]] && printf "\n\e[31;1mWarning!\nYou have reached more than 1 Kbyte of disk storage in the trash can.\e[0m\n\n"
}


trapCtrlC(){
	echo -e "\n\nTotal number of regular files in the trashCan"
    # The trap should indicate the current total number of regular files in the user’s trashCan directory in an appropriate message and then terminate the 
	stat --printf="%F\n" ./* | grep -c "regular"
    # exit and return status code 130 (Script terminated by Ctrl-C)
	exit 130
}

trapEndScript(){
	echo -e "\r\nGoodbye $(basename $HOME)!"
}

safeDel(){
	cd $current
	mv -v "$@" "$HOME/.trashCan"
}
main(){
	#checks if the trashCan dir exists. Creates one otherwise. The condition -s is to avoid printing an error to the screen if the trashCan exists.
	[[ -d "$HOME/.trashCan" ]] || mkdir "$HOME/.trashCan"
	cd "$HOME/.trashCan"
	# prints a warning message if the disk usage in the trashCan directory exceeds 1Kbytes. 
	storageWarning
}

list(){
	# Checks if the trashCan is empty. Lists its content if otherwise.
	if [[ -z "$(ls "$HOME/.trashCan")" ]]; 
	then
		echo "Trashcan is empty"
	else
		printf "%-23s %10s %18s\e[0m\n" "Filename" "Size" "Type"
		echo "-------------------------------------------------------------------------"
		for f in *; do
			printf "%-23s %10s \t\t %-20s\n" "$f" "$(stat --printf="%s" $f)" "$(file -b $f)"
		done
		printf "\n"
	fi
}

recover(){
	# checks that the arguments are not empty, and move them to current directory. 
	if [[ -n $@ ]]; then 
		mv -v $@ "$current" && printf "\e[32mFile(s) moved to $current successfully! \e[0m"
	fi
	echo ""
}

delete(){
	printf "\e[31;1mEmpty trash?(y/N) \e[0m"
	read ans
	#empties the trashcan from directories and files
	if [[ $ans =~ [y,Y] ]]; then 
		rm -rf $HOME/.trashCan/* && printf "Your trashcan has been emptied"
	else	
		#checks if trashcan is empty
		if [[ -z $(ls "$HOME/.trashCan") ]]; then
			echo "Trashcan is empty. Nothing to delete."
		else
		# if not empty, deletes files interactively with explanation
			rm -vi *
			# if any of the files is a directory, warns the user that they can't delete a directory
			if [ ! $? -eq 0 ]; then
				printf "\e[31;1mDeleting directories is not supported by safeDel!\e[0m"				
			fi 
		fi
	fi
	echo ""
}

total_usage(){
	# loops through the files in the trashcan and sums the sizes. Didn't use the du command to target files only and ignore directories.
	total_size=0
	if [ ! $(ls -l|wc -l) -eq 1 ]; then 
	for f in *
	do	
	    if [[ ! -d "$f" ]]; then
	      total_size=$((total_size + $(wc -c < "$f")))						
	    fi
	done
	fi
	printf "Total trashcan size is $total_size bytes. \n" 
}

monitor() {
	#gives permission to run the monitor script
	chmod 755 "$current/monitor.sh"
	#runs the monitor script in a new shell in the background
	gnome-terminal -x bash -c "$current/monitor.sh" &
}

move_to_trash(){
	# loops through the files in the args and moves them to the trashcan if they're files (not directories)
	for f in "$@"; do
		if [[ -f "$current/$f" ]];
		then
			mv "$current/$f" pwd && echo "$f was moved to trash"
		fi
	done
}

#simple function to format function headings
title(){
	printf "\e[36;1m\t\t\t---------------------------------------------\t\t\t\n"
	printf "\t\t\t\t    $@\n"
	printf "\t\t\t---------------------------------------------\t\t\t\n\e[0m\n"
}


usage() { 
	echo "This script can be run with or without options/arguments" 
	echo "Usage without any flag will open up an interactive menu driven version of safeDel. Usage with a filename will move the file(s) (if they exist) to the trashcan directory."
	printf "You can run it as follow: \n\t\t\tsafeDel [-r FILE] [-l] [-d] [-t] [-m] [-k]"
}

kill_monitor(){
	#kills the monitor process
	pkill -f "monitor.sh" && printf "You killed the monitor script ;_; T_T\n"
}
main

while getopts :lr:dtmk args #options
do
  case $args in

     l) title "Trashcan"
	      list;;
     r) title "recover file: \e[32m$OPTARG\e[0m"
	      recover $OPTARG;;
     d) title "delete option"
	      delete;; 
     t) title "total usage option"
	      total_usage;;
     m) title "monitor trashCan option"
	      monitor;; 
     k) title "kill monitor option"
	      kill_monitor;; 
     :) echo "data missing, option -$OPTARG";;
    \?) echo  usage;;
  esac
done

((pos = OPTIND - 1))
shift $pos

PS3='option> '


if (( $# == 0 ))
then if (( $OPTIND == 1 ))
 then select menu_list in list recover delete total monitor kill exit
      do case $menu_list in
         "list") 	title "\tTrashcan"
		 	list;;
         "recover")	title "Recovering file(s) to \n\t\t\t\t$current"
			printf "Enter filenames: \n"
			read f
		  	recover "$f";;
         "delete") 	title "\tDelete"
			delete;;
         "total") 	title "\ttotal usage"
			total_usage;;
         "monitor")	title "monitor trashCan"
			monitor;;
         "kill") 	title "\tkill monitor"
			kill_monitor;;
         "exit") 	exit 0;;
         *) echo "unknown option";;
         esac
      done
 fi
else 	
	#moves arguments representings existings files to the trashCan directory
	safeDel "$@"
fi


exit 0
