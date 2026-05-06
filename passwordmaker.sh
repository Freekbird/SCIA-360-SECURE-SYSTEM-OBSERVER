#!/bin/bash
read -p "Enter your Username: " USERNAME
read -s -p "Enter your Password: " PASSWORD
SALT=$(openssl rand -base64 16)
PASSWORD_HASH=$(echo -n "${SALT}${PASSWORD}" | sha256sum | awk '{print $1}')
ISADMIN="FALSE"
sqlite3 PASSWORDSFORSSO.db "INSERT INTO USERSALTPASS (USERNAME, SALT, PASSWORD, ADMIN) VALUES ('$USERNAME', '$SALT', '$PASSWORD_HASH', $ISADMIN);"
echo "User stored successfully."
# Show contents properly
sqlite3 PASSWORDSFORSSO.db "SELECT * FROM USERSALTPASS;"
