#!/bin/bash

AMI_ID="ami-0220d79f3f480ecf5"
SG_ID="sg-057e215dc23486bf8"
ZONE_ID="Z0498907312QP9JRHN116"
DOMAIN_NAME="wasdaws.cyou"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --count 1 --instance-type t3.micro --security-group-ids $SG_ID --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)
    # Get private Ip
    if [$instance -ne "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        RECORD_NAME="$instance.$DOMAIN_NAME" #mongodb.wasdaws.cyou
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        RECORD_NAME="$DOMAIN_NAME" #wasdaws.cyou
    fi
    echo "$instance - $IP"

    # aws route53 change-resource-record-sets \
    #     --hosted-zone-id $ZONE_ID \
    #     --change-batch '
    #     {
    #         "Comment": "Updating record set"
    #         ,"Changes": [{
    #         "Action"              : "UPSERT"
    #         ,"ResourceRecordSet"  : {
    #             "Name"              : "'$RECORD_NAME'"
    #             ,"Type"             : "A"
    #             ,"TTL"              : 1
    #             ,"ResourceRecords"  : [{
    #                 "Value"         : "'$IP'"
    #             }]
    #         }
    #         }]
    #     }
    #     '
    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch "{
        \"Comment\": \"Creating R53 records\",
        \"Changes\": [{
            \"Action\": \"UPSERT\",
            \"ResourceRecordSet\": {
                \"Name\": \"$RECORD_NAME\",
                \"Type\": \"A\",
                \"TTL\": 1,
                \"ResourceRecords\": [{\"Value\": \"$IP\"}]
            }
        }]
    }"  
done