#!/bin/bash

source ./common.sh
app_name="mongodb"

check_root

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying Mongodb repo"

dnf install mongodb-org -y &>>$LOG_FILE
VALIDATE $? "Installing mongodb server"

systemctl enable mongod &>>$LOG_FILE
VALIDATE $? "Enabling mongodb server"

systemctl start mongod &>>$LOG_FILE
VALIDATE $? "Starting mongodb server"  

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing Mongodb conf file for remote connections"

systemctl restart mongod &>>$LOG_FILE
VALIDATE $? "Restarting mongodb server"

print_time
