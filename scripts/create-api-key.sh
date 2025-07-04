#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <username> <tier>"
    echo "Tiers: free, pro, enterprise"
    exit 1
fi

USERNAME=$1
TIER=$2
API_KEY="nl-${TIER}-$(openssl rand -hex 8)"

echo "Creating API key for $USERNAME ($TIER tier)..."

# Create consumer
echo "Creating consumer..."
CONSUMER_RESULT=$(curl -s -X POST http://localhost:8001/consumers \
  --data username=$USERNAME \
  --data custom_id=$TIER)

echo "Consumer created: $CONSUMER_RESULT"

# Create API key
echo "Creating API key..."
KEY_RESULT=$(curl -s -X POST http://localhost:8001/consumers/$USERNAME/key-auth \
  --data key=$API_KEY)

echo "API key created: $KEY_RESULT"

# Set rate limits based on tier
case $TIER in
    free)
        MINUTE_LIMIT=60
        HOUR_LIMIT=1000
        ;;
    pro)
        MINUTE_LIMIT=1000
        HOUR_LIMIT=50000
        ;;
    enterprise)
        MINUTE_LIMIT=10000
        HOUR_LIMIT=500000
        ;;
    *)
        echo "Invalid tier. Use: free, pro, enterprise"
        exit 1
        ;;
esac

# Add rate limiting
echo "Adding rate limiting..."
RATE_RESULT=$(curl -s -X POST http://localhost:8001/consumers/$USERNAME/plugins \
  --data name=rate-limiting \
  --data config.minute=$MINUTE_LIMIT \
  --data config.hour=$HOUR_LIMIT \
  --data config.policy=local)

echo "Rate limiting added: $RATE_RESULT"

echo ""
echo "=========================================="
echo "API Key created successfully!"
echo "=========================================="
echo "Username: $USERNAME"
echo "Tier: $TIER"
echo "API Key: $API_KEY"
echo "Rate Limit: $MINUTE_LIMIT/min, $HOUR_LIMIT/hour"
echo ""
echo "Test with:"
echo "curl -H \"X-API-Key: $API_KEY\" https://api.nativetongueapis.com/v1/languages"
echo "=========================================="
