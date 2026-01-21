#!/bin/bash

START_TIME=$(date +%s)
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

dnf install golang -y &>>$LOG_FILE
VALIDATE $? "Installing Golang"

#To avoid repeated executions
id roboshop
    if [ $? -ne 0 ]
    then 
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
        VALIDATE $? "Creating roboshop system user" 
    else 
        echo -e "System user roboshop already created... $Y Skipping $N"
    fi

mkdir -p /app 
VALIDATE $? "Creating app directory" 

curl -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading dispatch"

cd /app 
unzip /tmp/dispatch.zip &>>$LOG_FILE
VALIDATE $? "Moving into app directory and unzipping dispatch"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service 
VALIDATE $? "Copying dispatch service"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable dispatch &>>$LOG_FILE
systemctl start dispatch
VALIDATE $? "Reloading, enabling and starting dispatch server"  

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script exection completed successfully, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE