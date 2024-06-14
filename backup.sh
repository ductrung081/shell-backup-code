#!/bin/bash

BACKUP_DIR="/root/backup"  # Replace with your backup directory path in the backup server

# Define the servers and directories
SERVERS=("SERVER1|user_name|server_ip" "SERVER2|user_name|server_ip2" "SERVER3|user_name|server_ip3")
#SERVER1: replace with SERVER INDEX
#user_name: ssh username, if you generate the ssh for root then put root
#server_ip: replace with the server contains web that need to back up

# Define server 1
SERVER1_WEBSITES=("number_backup_files|backup_folder_for_this_web|/var/www/html/website_folder" "number_backup_files|backup_folder_for_this_web|/var/www/html/website_folder");
#number_backup_files: [backupserver] number of backup files, 5 means the code will store 5 maximum backups for this web
#backup_folder_for_this_web: [backupserver] {BACKUP_DIR}/{number_backup_files} <- the folder of the backups in the backup server
#var/www/html/website_folder:  [webserver] replace with the path of the website in webs server

SERVER1_DATABASES=("backup_folder_for_this_web|database_name1" "backup_folder1|database_name2" "backup_folder2|database_name2");
#backup_folder_for_this_web: [backupserver]same as above
#database_name1: [webserver]database name of the web

SERVER1_USER_PASSWORD=("mysql_user_name" "mysql_password")
#mysql_user_name: [webserver] mysql username
#mysql_password: [webserver] mysql password

# Define server 2
SERVER2_WEBSITES=("10|backup_folder_for_this_web|/var/www/squarevest/Squarevest");
SERVER2_DATABASES=("backup_folder_for_this_web|database_name1");
SERVER2_USER_PASSWORD=("root" "mysql_password")

# # Define server 3
SERVER3_WEBSITES=("5|backup_folder_for_this_web|/var/www/squarevest/Squarevest");
SERVER3_DATABASES=("backup_folder_for_this_web|database_name1");
# SERVER3_USER_PASSWORD=("root" "mysql_password")



# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Log file
LOG_FILE="$BACKUP_DIR/backup.log"

# Function to log messages
log_message() {
  local MESSAGE="$1"
  echo "$(date +"%Y-%m-%d %H:%M:%S") - $MESSAGE" | tee -a "$LOG_FILE"
}

# Function to check if the last command executed successfully
check_command() {
  if [ $? -ne 0 ]; then
    log_message "Error: $1"
    exit 1
  fi
}

# Iterate over each server
for SERVER in "${SERVERS[@]}"; do
  log_message "Starting backup for $SERVER..."

    SERVER_NAME=$(echo "$SERVER" | cut -d'|' -f1)
    SERVER_USER=$(echo "$SERVER" | cut -d'|' -f2)
    SERVER_IP=$(echo "$SERVER" | cut -d'|' -f3)

    # Create server-specific backup directories
    TIMESTAMP=$(date +"%Y%m%d%H%M%S")
    DATEONLY=$(date +"%Y%m%d")

    # Get directories that need to back up
    SERVER_NAME_WEBSITE="${SERVER_NAME}_WEBSITES"
    SERVER_WEBSITES=$SERVER_NAME_WEBSITE[@]
    SERVER_WEBSITES=("${!SERVER_WEBSITES}")

    # # zip and backup website sources
    for WEBSITE_INFO in "${SERVER_WEBSITES[@]}"; do
        MAXIMUM_BACKUPS=$(echo "$WEBSITE_INFO" | cut -d'|' -f1)
        WEB_NAME=$(echo "$WEBSITE_INFO" | cut -d'|' -f2)
        WEB_DIR=$(echo "$WEBSITE_INFO" | cut -d'|' -f3)

        SERVER_BACKUP_DIR="$BACKUP_DIR/$WEB_NAME/$DATEONLY"
        mkdir -p "$SERVER_BACKUP_DIR"

        # limit the folder
        PARENT_DIR="$BACKUP_DIR/$WEB_NAME"
        COUNT=$(find "$PARENT_DIR" -mindepth 1 -type d | wc -l)
        if [ "$COUNT" -ge "$MAXIMUM_BACKUPS" ]; then
          OLDEST_FOLDER=$(find "$PARENT_DIR" -mindepth 1 -maxdepth 1 -type d -exec stat --format='%Y %n' {} \; | sort -n | head -n 1 | awk '{print $2}')
          rm -r "$OLDEST_FOLDER"
        fi
        # 


        log_message "SERVER_WEBSITES $WEB_NAME $WEB_DIR"
        WEB_FILE_NAME="web_${WEB_NAME}_${TIMESTAMP}.zip"

        # Backup the web directory
        log_message "Backing up code from $WEB_DIR..."
        SSH_CMD="cd $WEB_DIR && zip -r /tmp/${WEB_FILE_NAME} ."
        ssh "$SERVER_USER@$SERVER_IP" "$SSH_CMD"
        check_command "Failed to zip web code on $SERVER."
        scp "$SERVER_USER@$SERVER_IP:/tmp/${WEB_FILE_NAME}" "${SERVER_BACKUP_DIR}/${WEB_FILE_NAME}"
        check_command "Failed to transfer web code zip from $SERVER."
        ssh "$SERVER_USER@$SERVER_IP" "rm /tmp/${WEB_FILE_NAME}"
        check_command "Failed to remove temporary web code zip on $SERVER."
    done

    # # Backup the MySQL database
    DATABASE_PARAM="${SERVER_NAME}_DATABASES"
    DATABASES=$DATABASE_PARAM[@]
    DATABASES=("${!DATABASES}")

    DATABASE_USERS_PASS_PARAM="${SERVER_NAME}_USER_PASSWORD"
    USERS_PASS=$DATABASE_USERS_PASS_PARAM[@]
    USERS_PASS=("${!USERS_PASS}")
    DB_USER=${USERS_PASS[0]}
    DB_PASSWORD=${USERS_PASS[1]}

    for DATABASE in "${DATABASES[@]}"; do

        DATABASE_FOLDER=$(echo "$DATABASE" | cut -d'|' -f1)
        DATABASE_NAME=$(echo "$DATABASE" | cut -d'|' -f2)

        SERVER_BACKUP_DIR="$BACKUP_DIR/$DATABASE_FOLDER/$DATEONLY"
        mkdir -p "$SERVER_BACKUP_DIR"

        DB_FILE_NAME="db_${DATABASE_NAME}_${TIMESTAMP}.sql"
        DB_FILE_NAME_ZIP="db_${DATABASE_NAME}_${TIMESTAMP}.zip"
        log_message "Backing up database from $DATABASE_NAME..."
        SSH_CMD="mysqldump -u $DB_USER -p$DB_PASSWORD ${DATABASE_NAME} > /tmp/${DB_FILE_NAME} && zip /tmp/${DB_FILE_NAME_ZIP} /tmp/${DB_FILE_NAME} && rm /tmp/${DB_FILE_NAME}"
        ssh "$SERVER_USER@$SERVER_IP" "$SSH_CMD"
        check_command "Failed to dump and zip database on $SERVER."
        scp "$SERVER_USER@$SERVER_IP:/tmp/${DB_FILE_NAME_ZIP}" "${SERVER_BACKUP_DIR}/${DB_FILE_NAME_ZIP}"
        check_command "Failed to transfer database zip from $SERVER."
        ssh "$SERVER_USER@$SERVER_IP" "rm /tmp/${DB_FILE_NAME_ZIP}"
        check_command "Failed to remove temporary database zip on $SERVER."
    done

    log_message "Backup for $SERVER completed."
done

log_message "All backups completed."