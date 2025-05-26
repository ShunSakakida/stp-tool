#!/bin/zsh
# ./stg01.csv

echo "Starting bulk signup"

# Check if the CSV file exists
if [ ! -f "./stg01.csv" ]; then
    echo "Error: stg01.csv not found"
    exit 1
fi

echo "CSV file found"

# Read the CSV file line by line
while IFS=, read -r phone email; do
    # Remove any whitespace
    phone=$(echo $phone | tr -d ' ')
    email=$(echo $email | tr -d ' ')

    echo "Processing: Phone: $phone, Email: $email"

    # Call signup_stg01.sh with phone and email
    ./signup_stg01.sh "$phone" "$email"

    echo "signup completed"

    echo "----------------------------------------"
done < stg01.csv

