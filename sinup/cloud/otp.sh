#!/bin/bash
# bash ./otp.sh email 8803bd6f-cedb-4904-a862-da5379092776

# Check if required arguments are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 <session_id> <type>"
    exit 1
fi

type=$1
session_id=$2

# Validate type argument
if [ "$type" != "sms" ] && [ "$type" != "email" ]; then
    echo "Error: type must be either 'sms' or 'email'"
    exit 1
fi

otp=$(aws dynamodb scan \
    --table-name stp-stg01-auth-tbl \
    --filter-expression "contains(SK, :sk)" \
    --expression-attribute-values "{
        \":sk\": {\"S\": \"session#${session_id}#otp#${type}\"}
    }" \
    --region ap-northeast-1 \
    --profile stp-stg01 \
    --output json | jq -r '.Items[].otp.S')

echo "$otp"
