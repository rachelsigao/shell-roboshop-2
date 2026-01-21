#!/bin/bash

source ./common.sh
app_name="redis"

check_root

dnf module disable redis -y &>>$LOG_FILE
VALIDATE $? "Disabling Redis"

dnf module enable redis:7 -y &>>$LOG_FILE
VALIDATE $? "Enabling Redis:7"

dnf install redis -y &>>$LOG_FILE
VALIDATE $? "Installing Redis"

#i - permanent change, e - multiple expressions, s - substitute, Used | as delimiter for the second expression to avoid conflicts
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e 's|protected-mode yes|protected-mode no|' /etc/redis/redis.conf
VALIDATE $? "Editing Redis conf file for remote connections"

systemctl enable redis 
systemctl start redis 
VALIDATE $? "Enabling and Starting Redis"

print_time