#!/bin/bash

source ./common.sh
app_name="catalogue"

check_root
app_setup
nodejs_setup 
systemd_setup

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Copying Mongodb repo and installing Mongodb Client"

#to check if the data is loaded into mongodb
STATUS=$(mongosh --host mongodb.rachelsigao.online --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ] #can be anything above 0 which denotes that data is already loaded
then
    mongosh --host mongodb.rachelsigao.online </app/db/master-data.js &>>$LOG_FILE
    VALIDATE $? "Loading Data into Mongodb"
else 
    echo -e "Data is already loaded ... $Y Skipping"
fi

print_time