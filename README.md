# shell-backup-code
shell script to zip folders, and mysql data in multiple remote linux servers. It uses ssh key to remote to the webservers, zip the source codes, the databases, download to the backup server.

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