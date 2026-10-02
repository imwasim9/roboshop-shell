#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

set -euo pipefail
trap 'echo " There is a error at line number: $LINENO, Command is: $BASH_COMMAND"' ERR

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
LOG_FILE="$LOGS_FOLDER/SCRIPT_NAME.log" # /var/log/shell-roboshop/catalogue.log
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.wasdaws.cyou

USER_ID=$(id -u)

mkdir -p LOGS_FOLDER
echo "script started at: $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]; then
    echo -e "$R ERROR: $N Please run with sudo acess"
    exit 1
fi

# ******* node js ************
dnf module disable nodejs -y &>>$LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE
dnf install nodejs -y &>>$LOG_FILE
echo -e "Installing nodejs:20 ... $G SUCCESSFULL $N"

id roboshop &>>$LOG_FILE
if [ $? -n 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop user" roboshop
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
cd /app
rm -rf /app/* # when we run more than one time better to delete existing code and install new code
unzip /tmp/catalogue.zip
npm install &>>$LOG_FILE
cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE

INDEX=$(mongosh $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames.indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
else
    echo -e "Catalogue products were already loaded ...$Y SKIPPING $N"
fi

systemctl restart catalogue
echo "Restarted catalogue service ... $G SUCCESS $N"