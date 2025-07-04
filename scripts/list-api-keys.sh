#!/bin/bash

echo "Native Languages API - Key Management"
echo "====================================="

echo ""
echo "Active Consumers:"
echo "=================="
curl -s http://localhost:8001/consumers | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for consumer in data.get('data', []):
        username = consumer.get('username', 'N/A')
        tier = consumer.get('custom_id', 'N/A')
        print(f'{username} ({tier} tier)')
except:
    print('Error parsing consumer data')
"

echo ""
echo "All API Keys:"
echo "============="
curl -s http://localhost:8001/key-auths | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for key in data.get('data', []):
        api_key = key.get('key', 'N/A')
        consumer_id = key.get('consumer', {}).get('id', 'N/A')
        print(f'{api_key}')
except:
    print('Error parsing key data')
"

echo ""
echo "Rate Limiting Plugins:"
echo "====================="
curl -s http://localhost:8001/plugins | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for plugin in data.get('data', []):
        if plugin.get('name') == 'rate-limiting':
            consumer = plugin.get('consumer', {})
            if consumer:
                config = plugin.get('config', {})
                minute = config.get('minute', 'N/A')
                hour = config.get('hour', 'N/A')
                print(f'Consumer ID: {consumer.get(\"id\", \"N/A\")} - {minute}/min, {hour}/hour')
except:
    print('Error parsing plugin data')
"
