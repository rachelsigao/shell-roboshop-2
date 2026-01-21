#!/bin/bash

source ./common.sh
app_name="frontend"

check_root

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