
#!/bin/bash

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
		top -c
	else
		ps -eo pid,user,%cpu,%mem,cmd --sort=-%cpu | head -n 20
		sleep 2
	fi
	done
else
    whiptail --title "Invalid Credentials" --msgbox "Please try again" 8 78
    exit 1
fi
