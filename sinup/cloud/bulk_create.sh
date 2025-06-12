#!/bin/zsh
# bash ./bulk_signup.sh stg01
# ./stg01.csv

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
    echo "Usage: $0 <environment> [additional argument]"
    exit 1
fi

environment=$1
if [[ "$environment" != "dev" && "$environment" != "stg01" && "$environment" != "stg02" ]]; then
    echo "Invalid environment identifier. Must be one of: dev, stg01, stg02."
    exit 1
fi

is_create_individual_profile=$2
if [ "$is_create_individual_profile" == "0" ] || [ "$is_create_individual_profile" == "false" ]; then
    is_create_individual_profile=false
else
    is_create_individual_profile=true
fi


echo "Starting bulk signup"

# Check if the CSV file exists
file=./$environment.csv
if [ ! -f "$file" ]; then
    echo "Error: $environment.csv not found"
    exit 1
fi

echo "CSV file found"
echo ""

# Read the CSV file line by line
while IFS=, read -r phone email customer_type last_name first_name; do
    # Remove any whitespace
    phone=$(echo $phone | tr -d ' ')
    email=$(echo $email | tr -d ' ')
    customer_type=$(echo $customer_type | tr -d ' ')
    last_name=$(echo $last_name | tr -d ' ')
    first_name=$(echo $first_name | tr -d ' ')

    echo "Processing: Environment: $environment, Phone: $phone, Email: $email, Customer Type: $customer_type, Last Name: $last_name, First Name: $first_name ----------------------------------------"
    echo ""
    # Call signup.sh with phone and email
    access_token=$(./signup.sh "$environment" "$phone" "$email" "$customer_type")
    if [ $? -ne 0 ]; then
        echo "signup failed ----------------------------------------"
        continue
    fi
    echo ""
    echo "$access_token"
    echo ""
    echo "signup completed ----------------------------------------"

    if [ "$is_create_individual_profile" == false ]; then
        echo "create individual profile skipped ----------------------------------------"
        continue
    fi
    echo ""
    echo "create individual profile completed ----------------------------------------"
    echo ""
done < $file
