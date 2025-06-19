#!/bin/zsh
# bash ./create_individual_profile.sh stg01 token "テスト" "シナリオ"

if [ $# -lt 4 ]; then
    echo "Usage: $0 <environment> <last_name> <first_name> <access_token>" >&2
    exit 1
fi

environment=$1
if [[ "$environment" != "dev" && "$environment" != "stg01" && "$environment" != "stg02" ]]; then
    echo "Invalid environment identifier. Must be one of: dev, stg01, stg02."
    exit 1
fi

last_name=$2
first_name=$3
access_token=$4

# ベースURLとエンドポイントを定義
base_url="https://api.kdx-sto-$environment.com/v1"
endpoint="/customer/profile/individual"
origin="https://www.kdx-sto-$environment.com"
host="api.kdx-sto-$environment.com"



###############################################################
# Create Individual Profile
###############################################################
# リクエストのペイロードをJSON形式で作成
payload=$(cat <<EOF
{
    "individualProfile": {
        "firstName": "$first_name",
        "lastName": "$last_name",
        "firstNameKana": "テスト",
        "lastNameKana": "シナリオ",
        "gender": "male",
        "birthDate": {
            "year": 1999,
            "month": 12,
            "day": 31
        },
        "nationality": "japan",
        "isJapaneseResident": true,
        "countryOfResidence": "japan",
        "address": {
            "postCode": "1000011",
            "prefecture": "東京都",
            "city": "千代田区内幸町",
            "district": "千代田区内幸町２ー１ー６"
        },
        "employmentInfo": {
            "occupation": "employees_of_unlisted_companies_and_organizations",
            "industry": "information_and_communication"
        },
        "isPEPs": false,
        "isFATF": false,
        "isFATCA": false,
        "antiSocialForcesDeclaration": true
    },
    "individualInvestmentExp": {
        "investmentExperiences": [
            {
                "investmentProduct": "no_investment_experience",
                "experienceYear": 0
            }
        ],
        "investmentObjective": "emphasis_on_capital_appreciation",
        "personalFinancialInfo": {
            "incomeSource": "head_of_household_income",
            "annualIncome": 1000,
            "fundsCategory": "spare_funds",
            "financialAssets": 1000
        }
    },
    "stRegisteredInfo": {
        "hasST": true,
        "brokerageIDs": [
            "3"
        ],
        "stIntegration": true,
        "stLinkAgreement": 1
    }
}
EOF
)

response=$(curl -s -w "\n%{http_code}" -X POST "$base_url$endpoint" \
  -H "Origin: ${origin}" \
  -H "Content-Type: application/json" \
  -H "User-Agent: PostmanRuntime/7.43.0" \
  -H "Accept: */*" \
  -H "Authorization: Bearer $access_token" \
  -H "Cache-Control: no-cache" \
  -H "Host: ${host}" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -d "$payload")

# レスポンスのステータスコードとボディを分割
http_body=$(echo "$response" | sed '$d')
http_code=$(echo "$response" | tail -n1)


if [ "$http_code" -eq 200 ]; then
  echo "Create Individual Profile request successful" >&2
else
  echo "Create Individual Profile failed with status code: $http_code" >&2
  echo "Response: $http_body" >&2
  exit 1
fi
