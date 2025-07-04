#!/bin/bash

clear
echo "🌍 Native Languages API - Dashboard"
echo "=================================="
echo "Timestamp: $(date)"
echo ""

# System Status
echo "🖥️  System Status:"
echo "=================="
echo "Uptime: $(uptime | cut -d',' -f1 | cut -d' ' -f4-)"
echo "Memory: $(free -h | grep Mem | awk '{print $3 "/" $2}')"
echo "Disk: $(df -h / | tail -1 | awk '{print $3 "/" $2 " (" $5 ")"}')"

# Docker Status
echo ""
echo "🐳 Docker Services:"
echo "=================="
docker-compose ps --format "table {{.Name}}\t{{.State}}\t{{.Ports}}"

# API Tests
echo ""
echo "🔗 API Health Check:"
echo "==================="

# Test health endpoint
if curl -s -f https://api.nativetongueapis.com/health > /dev/null; then
    echo "✅ API Health: Healthy"
else
    echo "❌ API Health: Unhealthy"
fi

# Test with API key
if curl -s -H "X-API-Key: nl-free-demo-12345" https://api.nativetongueapis.com/v1/languages | grep -q "Swahili"; then
    echo "✅ API Functionality: Working"
else
    echo "❌ API Functionality: Not Working"
fi

# Kong Status
KONG_STATUS=$(curl -s http://localhost:8001/status | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    db_status = data.get('database', {}).get('reachable', False)
    print('✅ Database: Connected' if db_status else '❌ Database: Disconnected')
except:
    print('❌ Kong: Not responding')
")
echo "$KONG_STATUS"

# Active API Keys Count
echo ""
echo "🔑 API Keys:"
echo "============"
KEY_COUNT=$(curl -s http://localhost:8001/key-auths | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(f'Total Active Keys: {len(data.get(\"data\", []))}')
except:
    print('Error counting keys')
")
echo "$KEY_COUNT"

# Recent logs
echo ""
echo "📝 Recent Activity (Last 5 requests):"
echo "====================================="
docker-compose logs kong --tail=5 | grep -E "(GET|POST)" | tail -5 || echo "No recent activity"

echo ""
echo "Dashboard updated: $(date)"
echo "Run: watch -n 30 ./scripts/api-dashboard.sh (for auto-refresh)"
