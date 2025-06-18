#!/bin/zsh
# bash ./bulk_login_create_profile.sh stg01
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


echo "Starting bulk login"

# Check if the CSV file exists
file=./$environment.csv
if [ ! -f "$file" ]; then
    echo "Error: $environment.csv not found"
    exit 1
fi

echo "CSV file found"
echo ""

# Read the CSV file line by line
while IFS=, read -r phone email customer_type last_name first_name last_name_kana first_name_kana gender birthday post_code; do
    # Remove any whitespace
    phone=$(echo $phone | tr -d ' ')
    email=$(echo $email | tr -d ' ')
    customer_type=$(echo $customer_type | tr -d ' ')
    last_name=$(echo $last_name | tr -d ' ')
    first_name=$(echo $first_name | tr -d ' ')
    last_name_kana=$(echo $last_name_kana | tr -d ' ')
    first_name_kana=$(echo $first_name_kana | tr -d ' ')
    gender=$(echo $gender | tr -d ' ')
    birthday=$(echo $birthday | tr -d ' ')
    post_code=$(echo $post_code | tr -d ' ')

    echo "Processing parameters:"
    echo "----------------------------------------"
    echo "Environment: $environment"
    echo "Phone: $phone"
    echo "Email: $email"
    echo "Customer Type: $customer_type"
    echo "Last Name: $last_name"
    echo "First Name: $first_name"
    echo "Last Name Kana: $last_name_kana"
    echo "First Name Kana: $first_name_kana"
    echo "Gender: $gender"
    echo "Birthday: $birthday"
    echo "Post Code: $post_code"
    echo "----------------------------------------"
    echo ""
    # Call login.sh with phone and email
    access_token=$(./login.sh "$environment" "$email")
    if [ $? -ne 0 ]; then
        echo "login failed ----------------------------------------"
        continue
    fi
    echo ""
    echo "$access_token"
    echo ""
    echo "login completed ----------------------------------------"

    if [ "$is_create_individual_profile" == false ]; then
        echo "create individual profile skipped ----------------------------------------"
        continue
    fi

    ./create_individual_profile.sh "$environment" "$last_name" "$first_name" "$access_token"
    if [ $? -ne 0 ]; then
        echo "create individual profile failed ----------------------------------------"
        continue
    fi
    echo ""
    echo "create individual profile completed ----------------------------------------"
    echo ""
done < $file
