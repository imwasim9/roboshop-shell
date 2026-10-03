#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

##Use the below set and trap only once development of everything is done
## and script is stable. Better to use validate function till then
# set -euo pipefail
# trap 'echo " There is a error at line number: $LINENO, Command is: $BASH_COMMAND"' ERR

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-roboshop/user.log
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

# ******* node js ************
dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disabling nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs:20"
dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "installing nodejs:20"
# echo -e "Installing nodejs:20 ... $G SUCCESSFULL $N"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop user" roboshop
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"
curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading user application"
cd /app
VALIDATE $? "Changing to app directory"
rm -rf /app/* # when we run more than one time better to delete existing code and install new code
VALIDATE $? "Removing existing code"
unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "unzip user"

npm install &>>$LOG_FILE
VALIDATE $? "installing npm dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reload daemon"
systemctl enable user &>>$LOG_FILE
VALIDATE $? "Enable user"
systemctl restart user &>>$LOG_FILE
VALIDATE $? "restart user"
