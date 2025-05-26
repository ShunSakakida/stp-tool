# otp.sh
#!/bin/zsh

# 必要な変数を定義
entityType="otp"
sortKey="attempts_count"
base_url="http://localhost:4567"
table_name="auth"

# 引数からsendToとsessionIdを取得
sendTo="$1"
sessionId="$2"

# FilterExpressionを動的に構築
filterExpression="entity_type = :etype"
expressionAttributeValues="{\":etype\": {\"S\": \"$entityType\"}}"

if [ -n "$sendTo" ]; then
    filterExpression+=" AND send_to = :sendTo"
    expressionAttributeValues=$(echo "$expressionAttributeValues" | jq --arg sendTo "$sendTo" '. + {":sendTo": {"S": $sendTo}}')
fi

if [ -n "$sessionId" ]; then
    filterExpression+=" AND begins_with(SK, :sessionId)"
    expressionAttributeValues=$(echo "$expressionAttributeValues" | jq --arg sessionId "session#$sessionId" '. + {":sessionId": {"S": $sessionId}}')
fi

# リクエストペイロードを作成
payload=$(jq -n \
    --arg tableName "$table_name" \
    --arg filterExpression "$filterExpression" \
    --argjson expressionAttributeValues "$expressionAttributeValues" \
    '{
        TableName: $tableName,
        FilterExpression: $filterExpression,
        ExpressionAttributeValues: $expressionAttributeValues
    }')

# curlを使用してPOSTリクエストを送信
response=$(curl -s -w "\n%{http_code}" -X POST "$base_url" \
    -H "X-Amz-Target: DynamoDB_20120810.Scan" \
    -H "Content-Type: application/x-amz-json-1.0" \
    -d "$payload")

# レスポンスのステータスコードとボディを分割
http_body=$(echo "$response" | sed '$d')
http_code=$(echo "$response" | tail -n1)

# レスポンスを解析してOTPを取得
if [ "$http_code" -eq 200 ]; then
    items=$(echo "$http_body" | jq '.Items')
    if [ "$(echo "$items" | jq 'length')" -gt 0 ]; then
        sortedItems=$(echo "$items" | jq -S --arg sortKey "$sortKey" 'sort_by(.[$sortKey].N | tonumber)')
        otp=$(echo "$sortedItems" | jq -r '.[0].otp.S')
        echo "$otp"  # OTPを標準出力に出力
    else
        echo "No matching OTP found" >&2
        exit 1
    fi
else
    echo "Request failed with status code: $http_code" >&2
    exit 1
fi