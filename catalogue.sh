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
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-roboshop/catalogue.log
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.wasdaws.cyou

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
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading catalogue application"
cd /app &>>$LOG_FILE
VALIDATE $? "Changing to app directory"
rm -rf /app/* &>>$LOG_FILE # when we run more than one time better to delete existing code and install new code
VALIDATE $? "Removing existing code"
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzip catalogue"

npm install &>>$LOG_FILE
VALIDATE $? "installing npm dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue &>>$LOG_FILE
VALIDATE $? "Enable catalogue"


cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
VALIDATE $? "copying mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Install mongodb client"

INDEX=$(mongosh $MONGODB_HOST --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "load catalogue products"
else
    echo -e "Catalogue products were already loaded ...$Y SKIPPING $N"
fi

systemctl restart catalogue &>>$LOG_FILE
echo -e "Restarted catalogue service ... $G SUCCESS $N"
VALIDATE $? "Restarted catalogue"