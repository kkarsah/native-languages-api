#!/bin/bash

echo "Kong Status:"
curl -s http://localhost:8001/status | jq .

echo ""
echo "Recent API Requests:"
docker-compose logs kong --tail=10 | grep -E "(GET|POST|PUT|DELETE)"

echo ""
echo "Database Connections:"
docker-compose exec postgres psql -U nlapi -d native_languages -c "
SELECT 
    COUNT(*) as total_requests,
    DATE(created_at) as request_date
FROM api_usage 
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY DATE(created_at)
ORDER BY request_date DESC;
" 2>/dev/null || echo "No usage data in database yet"
