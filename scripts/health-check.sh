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
if curl -s http://localhost:3100/health | grep -q "healthy\|service\|status" 2>/dev/null; then
    echo "✓ Languages Service: Healthy"
else
    echo "✗ Languages Service: Unhealthy"
fi

# Check Audio Service (on exposed port 3101)
if curl -s http://localhost:3101/health | grep -q "healthy\|service\|status" 2>/dev/null; then
    echo "✓ Audio Service: Healthy"
else
    echo "✗ Audio Service: Unhealthy"
fi

echo ""
echo "System Resources:"
free -h | head -2
echo ""
df -h | head -2
