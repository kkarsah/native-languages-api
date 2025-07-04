#!/bin/bash

set -e

echo "Deploying Native Languages API..."

# Load environment variables
source .env

# Build and start services
echo "Building Docker images..."
docker-compose build

echo "Starting services..."
docker-compose up -d

# Wait for services
echo "Waiting for services to start..."
sleep 30

# Initialize Kong
echo "Initializing Kong..."
docker-compose exec kong kong migrations bootstrap --yes || true
docker-compose restart kong

echo "Deployment completed!"
echo "Services available at:"
echo "  - API: https://api.$DOMAIN"
echo "  - Monitoring: http://$(hostname -I | awk '{print $1}'):3000"
echo "  - Database Admin: http://$(hostname -I | awk '{print $1}'):8080"
