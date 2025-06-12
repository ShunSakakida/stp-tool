# !/bin/bash
# bash ./select_customer.sh stg01

if [ $# -lt 1 ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

# Check if the environment identifier is valid
environment=$1
if [[ "$environment" != "dev" && "$environment" != "stg01" && "$environment" != "stg02" ]]; then
    echo "Invalid environment identifier. Must be one of: dev, stg01, stg02."
    exit 1
fi

# Check if the CSV file exists
file=./$environment.csv
if [ ! -f "$file" ]; then
    echo "Error: $environment.csv not found"
    exit 1
fi

echo ""

# Read the CSV file line by line
while IFS=, read -r phone email customer_type last_name first_name; do
    # Remove any whitespace
    phone=$(echo $phone | tr -d ' ')
    email=$(echo $email | tr -d ' ')
    customer_type=$(echo $customer_type | tr -d ' ')
    last_name=$(echo $last_name | tr -d ' ')
    first_name=$(echo $first_name | tr -d ' ')


    customer_id=$(aws dynamodb scan \
        --table-name stp-$environment-customer-tbl \
        --filter-expression "email_address = :email_address" \
        --expression-attribute-values "{
            \":email_address\": {\"S\": \"$email\"}
        }" \
        --region ap-northeast-1 \
        --profile stp-$environment \
        --output json | jq -r '.Items[].PK.S | sub("^customer#"; "")')
    echo "$customer_id"

done < $file
