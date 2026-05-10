#!/bin/bash
CHOICE=$(
	whiptail --title "Log In or View Logs" --menu "Make your choice" 16 100 9 \
		"1)" "Log into SSO Task Manager" \
		"2)" "Log into Log Menu" \
		"3)" "End script" 3>&2 2>&1 1>&3
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

		timestamp=$(date +%Y%m%d_%H%M%S)
		echo "$USERNAME Logged into SSO at $timestamp" >> actionlog.txt
	
		if [[ "$ROLE" = "ADMIN" ]]; then
			
			while true; do
				clear
				top -b -n 1
				echo
				echo "Press 'p' to snapshot, 'q' to quit"
				read -t 3 -n 1 key
				case "$key" in
				p)
					timestamp=$(date +%Y%m%d_%H%M%S)

					FILE="snapshot_admin_${timestamp}_${FILEUSERNAME}.txt"

					top -b -n 1 -c >"$FILE"

					echo "Saved snapshot: $FILE"

					HASH=$(sha256sum "$FILE" | awk '{print $1}')
					echo "$FILE $HASH" >>integrity.txt
					echo "$USERNAME created a snapshot at $timestamp" > actionlog.txt
					;;
				q)
					break
					;;
				esac
			done
		else
			while true; do
				clear
				top -b -n 1 -u !root
				echo
				echo "Press 'p' to take a snapshot, 'q' to quit"
				read -t 3 -n 1 key
				case "$key" in
				p)
					timestamp=$(date +%Y%m%d_%H%M%S)
					FILE="snapshot_auditor_${timestamp}_${FILEUSERNAME}.txt"
					top -b -n 1 -u "!root" >"$FILE"
					HASH=$(sha256sum "$FILE" | awk '{print $1}')
					echo "Saved snapshot: $FILE"
					echo "$FILE $HASH" >>integrity.txt
					echo "$USERNAME created a snapshot at $timestamp" > actionlog.txt
					;;
				q)
					break
					;;
				esac
			done
		fi
	else
		whiptail --title "Invalid Credentials" --msgbox "Please try again" 8 78
		timestamp=$(date +%Y%m%d_%H%M%S)
		echo  "$USERNAME tried to log into the SSO Task Manager at $timestamp" >> actionlog.txt
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

	

		if [ -z "$FILEUSERNAME" ]; then
			whiptail --title "ERROR" --msgbox "Invalid Credentials" 8 78
			exit 1
		fi

		PASSWORDHASH=$(echo -n "${FILESALT}${PASSWORD}" | sha256sum | awk '{print $1}')

		if [[ "$PASSWORDHASH" == "$FILEPASSWD" ]]; then
			timestamp=$(date +%Y%m%d_%H%M%S)
			echo "$USERNAME logged into the file viewer and deletor at $timestamp" >> actionlog.txt
			CHOICE=$(
				whiptail --title "View Logs or Delete Logs" --menu "Make your choice" 16 100 9 \
				"1)" "View Logs" \
					"2)" "Delete Logs" 3>&2 2>&1 1>&3
				)


			case $CHOICE in #Viewing Logs Section

			"1)")

			files=()

			for f in snapshot_*.txt actionlog.txt warninglog.txt; do
				[ -e "$f" ] || continue
				files+=("$f" "$f")
			done

			LOGFILE=$(whiptail --title "Select Log File" --menu "Choose a log:" 20 100 10 \
				"${files[@]}" \
				3>&2 2>&1 1>&3)

			LOGHASH=$(sha256sum "$LOGFILE" | awk '{print $1}')
			STORED_HASH=$(awk -v file="$LOGFILE" '$1 == file {print $2}' integrity.txt | tr -d '\n')

			if [[ "$LOGHASH" == "$STORED_HASH" ]]; then
	
					timestamp=$(date +%Y%m%d_%H%M%S)
					echo "$USERNAME is viewing $LOGFILE at $timestamp" > actionlog.txt
					if [ -n "$LOGFILE" ]; then
					whiptail --title "Viewing $LOGFILE" --scrolltext --textbox "$LOGFILE" 20 100
				fi

			else

				whiptail --title "THIS FILE HAS BEEN TAMPERED WITH" --msgbox "THESE LOGS ARE INVALID" 40 40

			fi
			;;

			#Log Deleter

			"2)")
				if [[ "$ROLE" = "ADMIN" ]]; then
				timestamp=$(date +%Y%m%d_%H%M%S)
				echo "$USERNAME has entered the log deletor menu at $timestamp" >> actionlog.txt
				files=()

				for f in snapshot_*.txt actionlog.txt warninglog.txt; do
    					[ -e "$f" ] || continue
    					files+=("$f" "$f")
				done

				if [ ${#files[@]} -eq 0 ]; then 
				whiptail --msgbox "No snapshot logs found" 10 60 
				return 0 2>/dev/null || exit 0
				fi

				LOGFILE=$(whiptail --title "Select Log File to Delete" --menu "Choose a log:" 20 100 10 \
				    "${files[@]}" \
				    3>&2 2>&1 1>&3)

					LOGHASH=$(sha256sum "$LOGFILE" | awk '{print $1}')
					STORED_HASH=$(awk -v file="$LOGFILE" '$1 == file {print $2}' integrity.txt)
					if [[ "$LOGHASH" != "$STORED_HASH" ]]; then
  						whiptail --msgbox "Refusing to delete: file integrity mismatch" 10 60
    						exit 1
					else
						awk -v file="$LOGFILE" '$1 != file' integrity.txt > integritytemp.txt && mv integritytemp.txt integrity.txt
						rm -f "$LOGFILE"
						echo "$USERNAME deleted log file $LOGFILE at $timestamp" >> actionlog.txt
					fi
				
				else
					timestamp=$(date +%Y%m%d_%H%M%S)
					whiptail --msgbox "Invalid Credentials" 20 100 10
					echo "Warning: Auditor $USERNAME tried to delete a log file at $timestamp" >> warninglog.txt
					exit 0
				fi
			;;
			esac

		else
			timestamp=$(date +%Y%m%d_%H%M%S)
			whiptail --title "Invalid Credentials" --msgbox "Please try again" 8 78
			echo "$USERNAME tried to log into the log viewer and deletor at $timestamp" >> warninglog.txt
			exit 1

		fi
	;;

esac
case $CHOICE in
"3)")
	exit
	;;
esac
