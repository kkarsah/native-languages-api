#!/bin/bash

echo "Native Languages API - Health Check"
echo "==================================="

# Check services
docker-compose ps

echo ""
echo "Service Health:"

# Check Kong API Gateway
if curl -s -f http://localhost:8001/status > /dev/null; then
    echo "✓ Kong API Gateway: Healthy"
else
    echo "✗ Kong API Gateway: Unhealthy"
fi

# Check PostgreSQL
if docker-compose exec -T postgres pg_isready -U nlapi > /dev/null 2>&1; then
    echo "✓ PostgreSQL: Healthy"
else
    echo "✗ PostgreSQL: Unhealthy"
fi

# Check Redis
if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✓ Redis: Healthy"
else
    echo "✗ Redis: Unhealthy"
fi

# Check Languages Service (on exposed port 3100)
if curl -s -f http://localhost:3100/health > /dev/null 2>&1; then
    echo "✓ Languages Service: Healthy"
else
    echo "✗ Languages Service: Unhealthy"
fi

# Check Audio Service (on exposed port 3101)
if curl -s -f http://localhost:3101/health > /dev/null 2>&1; then
    echo "✓ Audio Service: Healthy"
else
    echo "✗ Audio Service: Unhealthy"
fi

# Check Users Service
if curl -s -f http://localhost:3102/health > /dev/null 2>&1; then
    echo "✓ Users Service: Healthy"
else
    echo "✗ Users Service: Unhealthy"
fi

# Check Analytics Service
if curl -s -f http://localhost:3103/health > /dev/null 2>&1; then
    echo "✓ Analytics Service: Healthy"
else
    echo "✗ Analytics Service: Unhealthy"
fi

# Check Admin Service
if curl -s -f http://localhost:3104/health > /dev/null 2>&1; then
    echo "✓ Admin Service: Healthy"
else
    echo "✗ Admin Service: Unhealthy"
fi

# Check Webhooks Service
if curl -s -f http://localhost:3105/health > /dev/null 2>&1; then
    echo "✓ Webhooks Service: Healthy"
else
    echo "✗ Webhooks Service: Unhealthy"
fi

echo ""
echo "API Functionality Tests:"

# Test authentication enforcement
AUTH_TEST=$(curl -s http://localhost:8000/v1/languages)
if echo "$AUTH_TEST" | grep -q "No API key"; then
    echo "✓ Authentication: Properly enforced"
else
    echo "✗ Authentication: Not enforced"
fi

# Test Free tier API
FREE_TEST=$(curl -s -H "X-API-Key: nl-free-demo-12345" http://localhost:8000/v1/languages)
if echo "$FREE_TEST" | grep -q "Native Languages API\|Swahili"; then
    echo "✓ Free Tier API: Working"
else
    echo "✗ Free Tier API: Not working"
fi

# Test Pro tier API
PRO_TEST=$(curl -s -H "X-API-Key: nl-pro-01e0d32563af96ad" http://localhost:8000/v1/languages)
if echo "$PRO_TEST" | grep -q "Native Languages API\|Swahili"; then
    echo "✓ Pro Tier API: Working"
else
    echo "✗ Pro Tier API: Not working"
fi

# Test HTTPS endpoints
HTTPS_TEST=$(curl -s -H "X-API-Key: nl-free-demo-12345" https://api.nativetongueapis.com/v1/languages)
if echo "$HTTPS_TEST" | grep -q "Native Languages API\|Swahili"; then
    echo "✓ HTTPS API: Working"
else
    echo "✗ HTTPS API: Not working"
fi

echo ""
echo "System Resources:"
free -h | head -2
echo ""
df -h | head -2
