#!/bin/bash

echo "Native Languages API - Enhanced Key Management"
echo "=============================================="

echo ""
echo "📊 Platform Statistics:"
echo "======================="
echo "Total Consumers: $(curl -s http://localhost:8001/consumers | jq '.data | length')"
echo "Total API Keys: $(curl -s http://localhost:8001/key-auths | jq '.data | length')"
echo "Active Plugins: $(curl -s http://localhost:8001/plugins | jq '.data | length')"

echo ""
echo "👥 Active Consumers & API Keys:"
echo "==============================="

# Get consumers with their API keys
curl -s http://localhost:8001/consumers | jq -r '.data[] | 
"Username: \(.username)
Tier: \(.custom_id // "N/A")
Consumer ID: \(.id)
Created: \(.created_at // "N/A")
─────────────────────────────"'

echo ""
echo "🔑 All API Keys:"
echo "==============="
curl -s http://localhost:8001/key-auths | jq -r '.data[] | .key'

echo ""
echo "⚡ Rate Limits by Consumer:"
echo "=========================="
curl -s http://localhost:8001/plugins | jq -r '
.data[] | 
select(.name == "rate-limiting") | 
"Consumer: \(.consumer.id // "Global")
Rate Limit: \(.config.minute // "N/A")/min, \(.config.hour // "N/A")/hour
Policy: \(.config.policy // "N/A")
─────────────────────────────"'

echo ""
echo "🌐 Services & Routes:"
echo "===================="
echo "Services: $(curl -s http://localhost:8001/services | jq '.data | length')"
echo "Routes: $(curl -s http://localhost:8001/routes | jq '.data | length')"

echo ""
echo "💡 Quick Test Commands:"
echo "======================="
echo "Test Free Tier:"
echo "curl -H \"X-API-Key: nl-free-demo-12345\" https://api.nativetongueapis.com/v1/languages"
echo ""
echo "Test Pro Tier:"
echo "curl -H \"X-API-Key: nl-pro-01e0d32563af96ad\" https://api.nativetongueapis.com/v1/languages"
