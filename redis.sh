#!/bin/bash

# color codes
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-roboshop/mongodb.log

mkdir -p $LOGS_FOLDER
echo "Script started at: $(date)" | tee -a $LOG_FILE

# getting the user id id -u, sudo id -u
USER_ID=$(id -u) # running the command using $()

if [ $USER_ID -ne 0 ]; then
   echo -e "$R ERROR$N:: Please run this script with root privelege" | tee -a $LOG_FILE
   # failure code is 1 and success code is 0 for exit status
   # 0 - sucess, 1-127 failure codes   
   exit 1 
fi


VALIDATE() {  #functions will recieve input via cmd line arguments just like shell script args
   if [ $1 -ne 0 ]; then
       echo -e "$R ERROR$N:: $2 failed please check logs" | tee -a $LOG_FILE
       exit 1 
   else 
       echo -e "$2 is $G successful$N" | tee -a $LOG_FILE
   fi 
}
dnf module disable redis -y
VALIDATE $? "disabling redis"
dnf module enable redis:7 -y
VALIDATE $? "enabling redis 7"
dnf install redis -y 
VALIDATE $? "installing redis 7"

sed -i -e "s/127.0.0.1/0.0.0.0/g" -e "/protected-mode/ c protected-mode no" /etc/redis/redis.conf

systemctl enable redis
VALIDATE $? "enable redis" 
systemctl start redis
VALIDATE $? "start redis" 