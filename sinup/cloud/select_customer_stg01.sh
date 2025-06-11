# !/bin/bash


# Check if the CSV file exists
if [ ! -f "./stg01.csv" ]; then
    echo "Error: stg01.csv not found"
    exit 1
fi


# Read the CSV file line by line
while IFS=, read -r phone email; do
    # Remove any whitespace
    phone=$(echo $phone | tr -d ' ')
    email=$(echo $email | tr -d ' ')

    customer_id=$(aws dynamodb scan \
        --table-name stp-stg01-customer-tbl \
        --filter-expression "email_address = :email_address" \
        --expression-attribute-values "{
            \":email_address\": {\"S\": \"$email\"}
        }" \
        --region ap-northeast-1 \
        --profile stp-stg01 \
        --output json | jq -r '.Items[].PK.S | sub("^customer#"; "")')
    echo "$customer_id"

done < stg01.csv
