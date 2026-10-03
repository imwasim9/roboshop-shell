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
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-roboshop/shipping.log
SCRIPT_DIR=$PWD
MYSQL_HOST=mysql.wasdaws.cyou

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

# ******* maven ************
dnf install maven -y &>>$LOG_FILE
VALIDATE $? "install maven"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop user" roboshop
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating app directory"
curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping application"
cd /app
VALIDATE $? "Changing to app directory"
rm -rf /app/* # when we run more than one time better to delete existing code and install new code
VALIDATE $? "Removing existing code"
unzip /tmp/shipping.zip
VALIDATE $? "unzip shipping"

mvn clean package &>>$LOG_FILE
mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE
VALIDATE $? "Copy systemctl service"

systemctl daemon-reload
systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "Enable shipping"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "installing mysql client"
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
VALIDATE $? "loading app schema"
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql &>>$LOG_FILE
VALIDATE $? "loading app user data"
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
VALIDATE $? "loading app master data"

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "restart shipping"