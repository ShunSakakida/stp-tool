#!/bin/zsh
# bash ./bulk_signup.sh stg01
# ./stg01.csv

if [ $# -lt 1 ]; then
    echo "Usage: $0 <environment>"
    exit 1
fi

environment=$1
if [[ "$environment" != "dev" && "$environment" != "stg01" && "$environment" != "stg02" ]]; then
    echo "Invalid environment identifier. Must be one of: dev, stg01, stg02."
    exit 1
fi


echo "Starting bulk signup"

# Check if the CSV file exists
file=./$environment.csv
if [ ! -f "$file" ]; then
    echo "Error: $environment.csv not found"
    exit 1
fi

echo "CSV file found"

# Read the CSV file line by line
while IFS=, read -r phone email customer_type; do
    # Remove any whitespace
    phone=$(echo $phone | tr -d ' ')
    email=$(echo $email | tr -d ' ')
    customer_type=$(echo $customer_type | tr -d ' ')

    echo "Processing: Phone: $phone, Email: $email, Customer Type: $customer_type"

    # Call signup.sh with phone and email
    ./signup.sh "$environment" "$phone" "$email" "$customer_type"

    echo "signup completed"

    echo "----------------------------------------"
done < $file
