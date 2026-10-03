#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-roboshop/frontend.log
SCRIPT_DIR=$PWD

USER_ID=$(id -u)

mkdir -p $LOGS_FOLDER
echo "script started at: $(date)" | tee -a $LOG_FILE

if [ $USER_ID -ne 0 ]; then
    echo -e "$R ERROR: $N Please run with sudo acess"
    exit 1
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "disabling nginx"
dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enabling nginx:1.24"
dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installing nginx:1.24"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "delete default html content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip  &>>$LOG_FILE
VALIDATE $? "download frontend code"
cd /usr/share/nginx/html &>>$LOG_FILE
VALIDATE $? "change dir to nginx"
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzip frontend code"
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "loaded nginx.conf"
systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restart nginx"