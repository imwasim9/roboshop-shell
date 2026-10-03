#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-roboshop/cart.log
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

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop user" roboshop
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading cart application"
cd /app
VALIDATE $? "Changing to app directory"
rm -rf /app/* # when we run more than one time better to delete existing code and install new code
VALIDATE $? "Removing existing code"
unzip /tmp/cart.zip
VALIDATE $? "unzip cart"

npm install &>>$LOG_FILE
VALIDATE $? "installing npm dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload
systemctl enable cart &>>$LOG_FILE
VALIDATE $? "Enable cart"
systemctl restart cart &>>$LOG_FILE
VALIDATE $? "restarted cart"
