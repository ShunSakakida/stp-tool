#!/bin/zsh

# ベースURLとエンドポイントを定義
base_url="http://localhost:8081"
endpoint="/customer/signup"

# ランダムな電話番号とメールアドレスを生成
random_phone_number="080$((RANDOM % 90000000 + 10000000))"
random_email_address="user$((RANDOM % 9000 + 1000))@kenedix-st.com"
type="signup"

###############################################################
# リクエスト① SignUp
###############################################################
# リクエストのペイロードをJSON形式で作成
payload=$(cat <<EOF
{
  "customerType": "individual",
  "emailAddress": "$random_email_address",
  "phoneNumber": "$random_phone_number"
}
EOF
)

# curlを使用してPOSTリクエストを送信
response=$(curl -s -w "\n%{http_code}" -X POST "$base_url$endpoint" \
  -H "Origin: http://localhost:3000" \
  -H "Content-Type: application/json" \
  -H "User-Agent: PostmanRuntime/7.43.0" \
  -H "Accept: */*" \
  -H "Cache-Control: no-cache" \
  -H "Host: localhost:8081" \
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
  echo "Request failed with status code: $http_code"
fi

###############################################################
# リクエスト② OTPSendEmail
###############################################################

# メールアドレスとセッションIDを設定
email_address="$random_email_address"  # 先のリクエストで使用したメールアドレス
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
  -H "Host: localhost:8081" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -d "$payload")

# レスポンスのステータスコードとボディを分割
http_body=$(echo "$response" | sed '$d')
http_code=$(echo "$response" | tail -n1)

# ステータスコードをチェックし、レスポンスを出力
if [ "$http_code" -eq 200 ]; then

  # OTPを取得
  otp=$(./otp.sh "email" "$session_id")
  if [ $? -eq 0 ]; then
    # do nothing
  else
    echo "Failed to retrieve OTP"
  fi
else
  echo "OTPSendEmail request failed with status code: $http_code"
  echo "Response:"
  echo "$http_body"
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
  -H "Host: localhost:8081" \
  -H "Accept-Encoding: gzip, deflate, br" \
  -H "Connection: keep-alive" \
  -d "$verify_payload")

# レスポンスのステータスコードとボディを分割
verify_http_body=$(echo "$verify_response" | sed '$d')
verify_http_code=$(echo "$verify_response" | tail -n1)

# ステータスコードをチェックし、レスポンスを出力
if [ "$verify_http_code" -eq 200 ]; then
  # do nothing
else
  echo "OTPVerify request failed with status code: $verify_http_code"
  echo "Response:"
  echo "$verify_http_body"
fi

###############################################################
# リクエスト④ OTPSendSMS
###############################################################

# SMS送信用のペイロードをJSON形式で作成
sms_payload=$(cat <<EOF
{
  "emailAddress": "$email_address",
  "phoneNumber": "$random_phone_number",
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
  -H "Host: localhost:8081" \
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

  else
    echo "Failed to retrieve SMS OTP"
  fi
else
  echo "OTPSendSMS request failed with status code: $sms_http_code"
  echo "Response:"
  echo "$sms_http_body"
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
  -H "Host: localhost:8081" \
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
  echo "\r\n"
  echo "$access_token"
  echo "\r\n"
else
  echo "OTPVerifySMS request failed with status code: $sms_verify_http_code"
  echo "Response:"
  echo "$sms_verify_http_body"
fi