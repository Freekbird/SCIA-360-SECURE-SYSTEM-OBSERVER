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

if [ -z "$FILEUSERNAME" ]; then
    whiptail --title "ERROR" --msgbox "USERNAME DOES NOT EXIST" 8 78
    exit 1
fi

PASSWORDHASH=$(echo -n "${FILESALT}${PASSWORD}" | sha256sum | awk '{print $1}')
if [[ "$PASSWORDHASH" == "$FILEPASSWD" ]]; then
    whiptail --title "SUCCESS" --msgbox "Login successful" 8 78
    exit 0
else
    whiptail --title "INVALID PASSWORD" --msgbox "Please try again" 8 78
    exit 1
fi
