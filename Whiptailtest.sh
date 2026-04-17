#!/bin/bash
USERNAME=$(whiptail --passwordbox "Please enter your Username" 8 78 --title "username dialog" 3>&1 1>&2 2>&3)
PASSWORD=$(whiptail --passwordbox "please enter your secret password" 8 78 --title "password dialog" 3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus == 0 ]; then

	#take  cleantext password, add the salt and then hash it
	#compare new hash with password hashs
	#if user and passwordhash match user and passwordhash in the Passwords.txt file then show the program normally
	#else kill the process 

	whiptail --title "Example Dialog" --msgbox "This is an example of a message box. You must hit OK to continue." 8 78
	else
    echo "User selected No, exit status was $?."
	fi
fi
echo "(Exit status was $exitstatus)"
