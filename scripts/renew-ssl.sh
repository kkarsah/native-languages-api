#!/bin/bash
# Stop nginx
docker-compose stop nginx

# Renew certificates
sudo certbot renew --standalone

# Copy new certificates
sudo cp /etc/letsencrypt/live/api.nativetongueapis.com/fullchain.pem ssl/
sudo cp /etc/letsencrypt/live/api.nativetongueapis.com/privkey.pem ssl/
sudo chmod 644 ssl/*.pem

# Start nginx
docker-compose up -d nginx
