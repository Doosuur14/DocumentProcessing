#!/bin/bash
echo "=== Document Processing System Test ==="
echo "Student: Факи Доосууур Дорис (faki)"
echo ""

API_URL="https://d5dk7fpq8a1j7aq4j90h.3zvepvee.apigw.yandexcloud.net"
echo "API: $API_URL"
echo ""

# 1. Upload documents
echo "Testing Upload..."
for i in 1 2; do
  FILE_NAME="test${i}.pdf"
  FILE_URL=""
  if [ "$i" -eq 1 ]; then
    FILE_URL="https://www.africau.edu/images/default/sample.pdf"
  else
    FILE_URL="https://github.com/mozilla/pdf.js/raw/master/examples/learning/helloworld.pdf"
  fi

  echo "Upload $i: $FILE_NAME"
  RESPONSE=$(curl -s -X POST "$API_URL/upload" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$FILE_NAME\",\"url\":\"$FILE_URL\"}")
  echo "Response: $RESPONSE"
done

echo ""
echo "Waiting for processing (30 seconds)..."
sleep 30

echo "Testing List Documents:"
DOCS=$(curl -s "$API_URL/documents")
echo "$DOCS"

KEYS=$(echo "$DOCS" | python3 - <<EOF
import json,sys
try:
    data=json.load(sys.stdin)
    keys = [doc.get("key","") for doc in data if "key" in doc and doc["key"]]
    print("\n".join(keys))
except:
    print("")
EOF
)

if [ -z "$KEYS" ]; then
  echo "No documents found in YDB."
else
  echo ""
  echo "Downloading documents..."
  for KEY in $KEYS; do
    echo "Downloading key: $KEY"
    curl -s -o "$KEY" "$API_URL/document/$KEY"
    echo "Downloaded $KEY size: $(wc -c < $KEY) bytes"
  done
fi
