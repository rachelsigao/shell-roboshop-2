#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-0c6ddf05e0664965e"
ZONE_ID="Z03171147RXIT58UUGL6"
DOMAIN_NAME="rachelsigao.online"

#to not allow empty values for instance names
if [ $# -eq 0 ]; 
then
  echo "Usage: $0 <instance-name> [instance-name ...]"
  exit 1
fi
 
#idempotent creation of instances and updating route53 records
for instance in "$@"
do
    echo "Checking instance: $instance"
    INSTANCE_ID=$(aws ec2 describe-instances --filters "Name=tag:Name,Values=$instance" "Name=instance-state-name,Values=running,stopped,pending" --query "Reservations[0].Instances[0].InstanceId" --output text)
    
    if [ "$INSTANCE_ID" == "None" ];  
    then
        echo "Instance not found. Creating $instance..."
        INSTANCE_ID=$(aws ec2 run-instances --image-id "$AMI_ID" --instance-type t3.micro --security-group-ids "$SG_ID" --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query "Instances[0].InstanceId" --output text)
        aws ec2 wait instance-running --instance-ids "$INSTANCE_ID"
    else
        echo "Instance already exists: $INSTANCE_ID"
    fi

#for getting IP address of the instance
    if [ "$instance" != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    fi

#updating route53 records
    RECORD_NAME="$instance.$DOMAIN_NAME."
    echo "Updating Route53 records"

    CHANGE_BATCH=$(cat <<EOF
{
  "Comment": "Idempotent DNS update for $instance",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$RECORD_NAME",
      "Type": "A",
      "TTL": 1,
      "ResourceRecords": [{
        "Value": "$IP"
      }]
    }
  }]
}
EOF
)

    aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "$CHANGE_BATCH"
    echo "$instance IP address: $IP"

# Link command: Update the main domain with the frontend IP
    if [ "$instance" == "frontend" ]; then
        MAIN_RECORD_NAME="$DOMAIN_NAME."
        MAIN_CHANGE_BATCH=$(cat <<EOF
{
  "Comment": "Linking main domain to frontend IP",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$MAIN_RECORD_NAME",
      "Type": "A",
      "TTL": 1,
      "ResourceRecords": [{
        "Value": "$IP"
      }]
    }
  }]
}
EOF
)
        aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "$MAIN_CHANGE_BATCH"
        echo "Main domain $DOMAIN_NAME updated with IP: $IP"
    fi

done