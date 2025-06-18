#!/bin/zsh
# bash ./signup.sh stg01 08059369965 shun.sakakida@kenedix-st.com individual


if [ $# -lt 4 ]; then
    echo "Usage: $0 <environment> <phone_number> <email_address> <customer_type>" >&2
    exit 1
fi

# Check if the environment identifier is valid
environment=$1
if [[ "$environment" != "dev" && "$environment" != "stg01" && "$environment" != "stg02" ]]; then
    echo "Invalid environment identifier. Must be one of: dev, stg01, stg02." >&2
    exit 1
fi

phone_number=$2
email_address=$3
customer_type=$4


# ベースURLとエンドポイントを定義
base_url="https://api.kdx-sto-$environment.com/v1"
endpoint="/customer/signup"
origin="https://www.kdx-sto-$environment.com"
host="api.kdx-sto-$environment.com"
type="signup"

###############################################################
# リクエスト① SignUp
###############################################################
# リクエストのペイロードをJSON形式で作成
payload=$(cat <<EOF
{
  "customerType": "$customer_type",
  "emailAddress": "$email_address",
  "phoneNumber": "$phone_number"
}
EOF
)

# curlを使用してPOSTリクエストを送信
response=$(curl -s -w "\n%{http_code}" -X POST "$base_url$endpoint" \
  -H "Origin: ${origin}" \
  -H "Content-Type: application/json" \
  -H "User-Agent: PostmanRuntime/7.43.0" \
  -H "Accept: */*" \
  -H "Cache-Control: no-cache" \
  -H "Host: ${host}" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -d "$payload")

# レスポンスのステータスコードとボディを分割
http_body=$(echo "$response" | sed '$d')
http_code=$(echo "$response" | tail -n1)

# ステータスコードをチェックし、sessionIDを出力
if [ "$http_code" -eq 200 ]; then
  session_id=$(echo "$http_body" | jq -r '.sessionID')
else
  echo "Request failed with status code: $http_code" >&2
  echo "Request failed with status body: $http_body" >&2
  exit 1
fi

###############################################################
# リクエスト② OTPSendEmail
###############################################################

# メールアドレスとセッションIDを設定
email_address="$email_address"  # 先のリクエストで使用したメールアドレス
session_id="$session_id"  # 先のリクエストで取得したセッションID

# リクエストのペイロードをJSON形式で作成
payload=$(cat <<EOF
{
  "emailAddress": "$email_address",
  "sessionID": "$session_id"
}
EOF
)

# curlを使用してPOSTリクエストを送信
response=$(curl -s -w "\n%{http_code}" -X POST "$base_url/customer/otp/send/email?type=$type" \
  -H "Content-Type: application/json" \
  -H "User-Agent: PostmanRuntime/7.43.0" \
  -H "Accept: */*" \
  -H "Cache-Control: no-cache" \
  -H "Host: ${host}" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -d "$payload")

# レスポンスのステータスコードとボディを分割
http_body=$(echo "$response" | sed '$d')
http_code=$(echo "$response" | tail -n1)

# ステータスコードをチェックし、レスポンスを出力
if [ "$http_code" -eq 200 ]; then
  echo "OTPSendEmail request successful" >&2
  # OTPを取得
  otp=$(./otp.sh "email" "$session_id")
  if [ $? -eq 0 ]; then
    # do nothing
    echo "OTP retrieved successfully" >&2
  else
    echo "Failed to retrieve OTP" >&2
    exit 1
  fi
else
  echo "OTPSendEmail request failed with status code: $http_code" >&2
  echo "Response: $http_body" >&2
  exit 1
fi


###############################################################
# リクエスト③ OTPVerifyEmail
###############################################################

# OTP検証のペイロードをJSON形式で作成
verify_payload=$(cat <<EOF
{
  "emailAddress": "$email_address",
  "otp": "$otp",
  "sessionID": "$session_id"
}
EOF
)

# curlを使用してOTP検証リクエストを送信
verify_response=$(curl -s -w "\n%{http_code}" -X POST "$base_url/customer/otp/verify/email?type=$type" \
  -H "Content-Type: application/json" \
  -H "User-Agent: PostmanRuntime/7.43.0" \
  -H "Accept: */*" \
  -H "Cache-Control: no-cache" \
  -H "Host: ${host}" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -d "$verify_payload")

# レスポンスのステータスコードとボディを分割
verify_http_body=$(echo "$verify_response" | sed '$d')
verify_http_code=$(echo "$verify_response" | tail -n1)

# ステータスコードをチェックし、レスポンスを出力
if [ "$verify_http_code" -eq 200 ]; then
  # do nothing
  echo "OTPVerify request successful" >&2
else
  echo "OTPVerify request failed with status code: $verify_http_code" >&2
  echo "Response:" >&2
  echo "$verify_http_body" >&2
  exit 1
fi

###############################################################
# リクエスト④ OTPSendSMS
###############################################################

# SMS送信用のペイロードをJSON形式で作成
sms_payload=$(cat <<EOF
{
  "emailAddress": "$email_address",
  "phoneNumber": "$phone_number",
  "sessionID": "$session_id"
}
EOF
)

# curlを使用してSMS送信リクエストを送信
sms_response=$(curl -s -w "\n%{http_code}" -X POST "$base_url/customer/otp/send/sms?type=$type" \
  -H "Content-Type: application/json" \
  -H "User-Agent: PostmanRuntime/7.43.0" \
  -H "Accept: */*" \
  -H "Cache-Control: no-cache" \
  -H "Host: ${host}" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -d "$sms_payload")

# レスポンスのステータスコードとボディを分割
sms_http_body=$(echo "$sms_response" | sed '$d')
sms_http_code=$(echo "$sms_response" | tail -n1)

# ステータスコードをチェックし、レスポンスを出力
if [ "$sms_http_code" -eq 200 ]; then

  # SMS用のOTPを取得
  sms_otp=$(./otp.sh "sms" "$session_id")
  if [ $? -eq 0 ]; then
    echo "OTP retrieved successfully" >&2
  else
    echo "Failed to retrieve SMS OTP" >&2
    exit 1
  fi
else
  echo "OTPSendSMS request failed with status code: $sms_http_code" >&2
  echo "Response:" >&2
  echo "$sms_http_body" >&2
  exit 1
fi

###############################################################
# リクエスト⑤ OTPVerifySMS
###############################################################

# SMS OTP検証のペイロードをJSON形式で作成
sms_verify_payload=$(cat <<EOF
{
  "emailAddress": "$email_address",
  "otp": "$sms_otp",
  "sessionID": "$session_id"
}
EOF
)

# curlを使用してSMS OTP検証リクエストを送信
sms_verify_response=$(curl -s -w "\n%{http_code}" -X POST "$base_url/customer/otp/verify/sms?type=signup" \
  -H "Content-Type: application/json" \
  -H "User-Agent: PostmanRuntime/7.43.0" \
  -H "Accept: */*" \
  -H "Cache-Control: no-cache" \
  -H "Host: ${host}" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -d "$sms_verify_payload")

# レスポンスのステータスコードとボディを分割
sms_verify_http_body=$(echo "$sms_verify_response" | sed '$d')
sms_verify_http_code=$(echo "$sms_verify_response" | tail -n1)

# ステータスコードをチェックし、レスポンスを出力
if [ "$sms_verify_http_code" -eq 200 ]; then
  # アクセストークンを抽出して表示
  access_token=$(echo "$sms_verify_http_body" | jq -r '.accessToken')
  echo "$access_token"
  exit 0
else
  echo "OTPVerifySMS request failed with status code: $sms_verify_http_code" >&2
  echo "Response:" >&2
  echo "$sms_verify_http_body" >&2
  exit 1
fi