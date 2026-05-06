#!/bin/bash
CHOICE=$(
whiptail --title "Log In or View Logs" --menu "Make your choice" 16 100 9 \
	"1)" "Log into SSO Task Manager"   \
	"2)" "Log in and View Logs"   \
	"3)" "End script"  3>&2 2>&1 1>&3
)

#LOG IN SCREEN
case $CHOICE in
	"1)")
USERNAME=$(whiptail --inputbox "Enter Username" 8 78 3>&1 1>&2 2>&3)
PASSWORD=$(whiptail --passwordbox "Enter Password" 8 78 3>&1 1>&2 2>&3)

exitstatus=$?

if [ $exitstatus -ne 0 ]; then
    exit 1
fi

FILEUSERNAME=$(sqlite3 PASSWORDSFORSSO.db "SELECT USERNAME FROM USERSALTPASS WHERE USERNAME='$USERNAME';")
FILESALT=$(sqlite3 PASSWORDSFORSSO.db "SELECT SALT FROM USERSALTPASS WHERE USERNAME='$USERNAME';")
FILEPASSWD=$(sqlite3 PASSWORDSFORSSO.db "SELECT PASSWORD FROM USERSALTPASS WHERE USERNAME='$USERNAME';")

role=$(sqlite3 PASSWORDSFORSSO.db "SELECT ADMIN FROM USERSALTPASS WHERE USERNAME='$USERNAME' LIMIT 1;")
if [ "$role" = "1" ]; then
	ROLE="ADMIN"
else
	ROLE="AUDITOR"
fi

if [ -z "$FILEUSERNAME" ]; then
    whiptail --title "ERROR" --msgbox "Invalid Credentials" 8 78
    exit 1
fi

PASSWORDHASH=$(echo -n "${FILESALT}${PASSWORD}" | sha256sum | awk '{print $1}')
if [[ "$PASSWORDHASH" == "$FILEPASSWD" ]]; then
	while true; do
	if [[ "$ROLE" = "ADMIN" ]]; then
		clear
		top -b -n 1
		echo "Press 'p' to snapshot, 'q' to quit"
		read -n 1 -s key

    		case "$key" in
        	p)
            	timestamp=$(date +%Y%m%d_%H%M%S)
            	top -b -n 1 -c > "snapshot_admin_$timestamp.txt"
           	 echo "Saved snapshot"
           	FILE="snapshot_admin_$timestamp.txt"
		HASH=$(sha256sum "$FILE" | awk '{print $1}')
		echo "$FILE $HASH" >> integrity.txt
		 ;;
		q)
			break
			;;
		esac
	else
		clear
		ps -eo pid,user,%cpu,%mem,cmd --sort=-%cpu | head -n 20
		echo "Press 'p' to take a snapshot, 'q' to quit"
		read -n 1 -s key
		case "$key" in
		p)
		timestamp=$(date +%Y%m%d_%H%M%S)
		ps -eo pid,user,%cpu,%mem,cmd --sort=-%cpu | head -n 2 > "snapshot_auditor_$timestamp.txt"
		FILE="snapshot_auditor_$timestamp.txt"
		HASH=$(sha256sum "$FILE" | awk '{print $1}')
		echo "$FILE $HASH" >> integrity.txt
		;;
		q)
			break
			;;
		esac
	fi
	done
else
    whiptail --title "Invalid Credentials" --msgbox "Please try again" 8 78
    exit 1
fi
;;
esac

#VIEW LOG FILES
case $CHOICE in

"2)")

USERNAME=$(whiptail --inputbox "Enter Username" 8 78 3>&1 1>&2 2>&3)

PASSWORD=$(whiptail --passwordbox "Enter Password" 8 78 3>&1 1>&2 2>&3)

exitstatus=$?

if [ $exitstatus -ne 0 ]; then
    exit 1
fi

FILEUSERNAME=$(sqlite3 PASSWORDSFORSSO.db "SELECT USERNAME FROM USERSALTPASS WHERE USERNAME='$USERNAME';")

FILESALT=$(sqlite3 PASSWORDSFORSSO.db "SELECT SALT FROM USERSALTPASS WHERE USERNAME='$USERNAME';")

FILEPASSWD=$(sqlite3 PASSWORDSFORSSO.db "SELECT PASSWORD FROM USERSALTPASS WHERE USERNAME='$USERNAME';")

role=$(sqlite3 PASSWORDSFORSSO.db "SELECT ADMIN FROM USERSALTPASS WHERE USERNAME='$USERNAME' LIMIT 1;")

if [ "$role" = "1" ]; then
    ROLE="ADMIN"
else
    ROLE="AUDITOR"
fi

if [[ "$ROLE" = "ADMIN" ]]; then

    if [ -z "$FILEUSERNAME" ]; then
        whiptail --title "ERROR" --msgbox "Invalid Credentials" 8 78
        exit 1
    fi

    PASSWORDHASH=$(echo -n "${FILESALT}${PASSWORD}" | sha256sum | awk '{print $1}')

    if [[ "$PASSWORDHASH" == "$FILEPASSWD" ]]; then

        files=()

        for f in snapshot_*.txt; do
            [ -e "$f" ] || continue
            files+=("$f" "$f")
        done

        LOGFILE=$(whiptail --title "Select Log File" --menu "Choose a log:" 20 100 10 \
            "${files[@]}" \
            3>&2 2>&1 1>&3)
	
	LOGHASH=$(sha256sum "$LOGFILE" | awk '{print $1}')
        STORED_HASH=$(awk -v file="$LOGFILE" '$1 == file {print $2}' integrity.txt | tr -d '\n')

        if [[ "$LOGHASH" == "$STORED_HASH" ]]; then

            if [ -n "$LOGFILE" ]; then
                whiptail --title "Viewing $LOGFILE" --scrolltext --textbox "$LOGFILE" 20 100
            fi

        else

            whiptail --title "THIS FILE HAS BEEN TAMPERED WITH" --msgbox "THESE LOGS ARE INVALID" 40 40

        fi


    else

        whiptail --title "Invalid Credentials" --msgbox "Please try again" 8 78
        exit 1

    fi
fi
;;

esac
case $CHOICE in
	"3)")
exit
;;
esac
