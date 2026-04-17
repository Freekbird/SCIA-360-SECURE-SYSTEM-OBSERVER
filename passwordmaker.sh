#!/bin/bash
read -p "Enter Your Username: " USERNAME
read -p "Enter Your Password: " PASSWORD
SALT=$(openssl rand -base64 16)
PASSWORD_HASH=$(echo -n "${SALT}${PASSWORD}" | sha256sum | awk '{print $1}')
sqlite3 my_database.db "INSERT INTO users (USERNAME, PASSWORD, SALT) VALUES ('$USERNAME', $PASSWORD, $SALT);"
cat Passwords.txt
