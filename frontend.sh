#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/roboshop-logs" 
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

#check for root access
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR: $N Please run this script with root access" | tee -a $LOG_FILE
    exit 1 #give other than 0 upto 127
else
    echo "You are running with root access, Script is being installed" | tee -a $LOG_FILE
fi

#Validate function takes input as exit status, what command they tried to install
VALIDATE ()
    {
    if [ $1 -eq 0 ]
    then 
        echo -e "$2 is $G SUCCESS $N" | tee -a $LOG_FILE
    else 
        echo -e "$2 is $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
    }

dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Disabling Nginx"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nginx: 1.24"

dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx 
systemctl start nginx 
VALIDATE $? "Enabling and Starting Nginx"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "Removing default content in Web Server"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
VALIDATE $? "Downlaoding Frontend content"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "Moving into app directory and unzipping frontend"

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE #remove default content in nginx.conf and copy the one we created (replaced local host with catalogue server)
VALIDATE $? "Removing default content in Web Server"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf 
VALIDATE $? "Copying nginx.conf"

systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "Restarting Nginx"