#!/bin/bash

# Native Languages API - Streamlined Infrastructure Setup
# Optimized for quick deployment

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
DOMAIN="nativetongueapis.com"
PROJECT_NAME="native-languages-api"
ENVIRONMENT=${1:-production}

print_status "Starting Native Languages API Infrastructure Setup"
print_status "Domain: $DOMAIN"
print_status "Environment: $ENVIRONMENT"

# =============================================================================
# STEP 1: System Updates and Dependencies
# =============================================================================

print_status "Step 1: Installing system dependencies..."

# Update system packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    htop \
    nginx \
    certbot \
    python3-certbot-nginx \
    ufw \
    fail2ban \
    postgresql-client \
    redis-tools

# Install Docker
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo usermod -aG docker $USER
    print_success "Docker installed successfully"
else
    print_success "Docker already installed"
fi

# Install Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose installed successfully"
else
    print_success "Docker Compose already installed"
fi

# Install Node.js
if ! command -v node &> /dev/null; then
    print_status "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_success "Node.js installed successfully"
else
    print_success "Node.js already installed"
fi

# =============================================================================
# STEP 2: Project Structure Setup
# =============================================================================

print_status "Step 2: Setting up project structure..."

# Create directory structure
mkdir -p {docker,config,scripts,services,docs,monitoring,ssl,backups}
mkdir -p services/{languages,audio,users,analytics}
mkdir -p config/{nginx,kong,postgres,redis}
mkdir -p monitoring/{dashboards,alerts}

# Create environment file
cat > .env << EOF
# Environment Configuration
ENVIRONMENT=$ENVIRONMENT
DOMAIN=$DOMAIN
PROJECT_NAME=$PROJECT_NAME

# Database Configuration
DB_HOST=postgres
DB_PORT=5432
DB_NAME=native_languages
DB_USER=nlapi
DB_PASSWORD=$(openssl rand -base64 32)

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=$(openssl rand -base64 32)

# Security Configuration
JWT_SECRET=$(openssl rand -base64 64)
API_KEY_SECRET=$(openssl rand -base64 32)
ADMIN_PASSWORD=$(openssl rand -base64 16)

# Storage Configuration
S3_BUCKET=native-languages-audio
AWS_REGION=us-east-1

# Rate Limiting
RATE_LIMIT_FREE=60
RATE_LIMIT_PRO=1000
RATE_LIMIT_ENTERPRISE=10000
EOF

print_success "Project structure created"

# =============================================================================
# STEP 3: Docker Compose Configuration
# =============================================================================

print_status "Step 3: Creating Docker Compose configuration..."

cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  # =============================================================================
  # LOAD BALANCER
  # =============================================================================
  
  nginx:
    image: nginx:1.25-alpine
    container_name: nginx-gateway
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config/nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./config/nginx/conf.d:/etc/nginx/conf.d
      - ./ssl:/etc/nginx/ssl
    restart: unless-stopped
    networks:
      - api-network

  # =============================================================================
  # API GATEWAY
  # =============================================================================
  
  kong:
    image: kong:3.4-alpine
    container_name: kong-gateway
    environment:
      - KONG_DATABASE=postgres
      - KONG_PG_HOST=postgres
      - KONG_PG_PORT=5432
      - KONG_PG_USER=${DB_USER}
      - KONG_PG_PASSWORD=${DB_PASSWORD}
      - KONG_PG_DATABASE=kong
      - KONG_PROXY_ACCESS_LOG=/dev/stdout
      - KONG_ADMIN_ACCESS_LOG=/dev/stdout
      - KONG_PROXY_ERROR_LOG=/dev/stderr
      - KONG_ADMIN_ERROR_LOG=/dev/stderr
      - KONG_ADMIN_LISTEN=0.0.0.0:8001
    ports:
      - "8000:8000"
      - "8001:8001"
    depends_on:
      - postgres
    restart: unless-stopped
    networks:
      - api-network

  # =============================================================================
  # MICROSERVICES
  # =============================================================================
  
  languages-service:
    build: ./services/languages
    container_name: languages-service
    environment:
      - NODE_ENV=${ENVIRONMENT}
      - DB_HOST=${DB_HOST}
      - DB_PASSWORD=${DB_PASSWORD}
      - REDIS_HOST=${REDIS_HOST}
      - REDIS_PASSWORD=${REDIS_PASSWORD}
    depends_on:
      - postgres
      - redis
    restart: unless-stopped
    networks:
      - api-network

  audio-service:
    build: ./services/audio
    container_name: audio-service
    environment:
      - NODE_ENV=${ENVIRONMENT}
      - DB_HOST=${DB_HOST}
      - DB_PASSWORD=${DB_PASSWORD}
      - REDIS_HOST=${REDIS_HOST}
      - REDIS_PASSWORD=${REDIS_PASSWORD}
    depends_on:
      - postgres
      - redis
    restart: unless-stopped
    networks:
      - api-network
    volumes:
      - audio-storage:/app/uploads

  # =============================================================================
  # DATABASES
  # =============================================================================
  
  postgres:
    image: postgres:15-alpine
    container_name: postgres-db
    environment:
      - POSTGRES_DB=${DB_NAME}
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./config/postgres/init:/docker-entrypoint-initdb.d
    restart: unless-stopped
    networks:
      - api-network

  redis:
    image: redis:7-alpine
    container_name: redis-cache
    command: redis-server --requirepass ${REDIS_PASSWORD} --appendonly yes
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped
    networks:
      - api-network

  # =============================================================================
  # MONITORING
  # =============================================================================
  
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${ADMIN_PASSWORD}
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    restart: unless-stopped
    networks:
      - api-network

  # =============================================================================
  # UTILITIES
  # =============================================================================
  
  adminer:
    image: adminer:latest
    container_name: adminer
    ports:
      - "8080:8080"
    depends_on:
      - postgres
    restart: unless-stopped
    networks:
      - api-network

volumes:
  postgres_data:
  redis_data:
  grafana_data:
  audio-storage:

networks:
  api-network:
    driver: bridge
EOF

print_success "Docker Compose configuration created"

# =============================================================================
# STEP 4: Nginx Configuration
# =============================================================================

print_status "Step 4: Setting up Nginx configuration..."

mkdir -p config/nginx/conf.d

# Main nginx configuration
cat > config/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    client_max_body_size 100M;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

    # Include additional configurations
    include /etc/nginx/conf.d/*.conf;
}
EOF

# API configuration
cat > config/nginx/conf.d/api.conf << 'EOF'
upstream kong_upstream {
    server kong:8000;
    keepalive 32;
}

server {
    listen 80;
    server_name api.nativetongueapis.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.nativetongueapis.com;

    # SSL configuration
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    # Security headers
    add_header Strict-Transport-Security "max-age=63072000" always;

    location / {
        proxy_pass http://kong_upstream;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}

# Main domain
server {
    listen 80;
    server_name nativetongueapis.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name nativetongueapis.com;

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    root /var/www/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

print_success "Nginx configuration created"

# =============================================================================
# STEP 5: Database Initialization
# =============================================================================

print_status "Step 5: Setting up database initialization..."

mkdir -p config/postgres/init

cat > config/postgres/init/01-init-databases.sql << 'EOF'
-- Create Kong database
CREATE DATABASE kong;
GRANT ALL PRIVILEGES ON DATABASE kong TO nlapi;

-- Switch to native_languages database
\c native_languages;

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Create languages table
CREATE TABLE IF NOT EXISTS languages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(10) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    native_name VARCHAR(100),
    iso_code VARCHAR(10),
    region VARCHAR(50),
    speakers_count INTEGER,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create words table
CREATE TABLE IF NOT EXISTS words (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    language_id UUID REFERENCES languages(id) ON DELETE CASCADE,
    word VARCHAR(200) NOT NULL,
    translation VARCHAR(200),
    phonetic VARCHAR(300),
    part_of_speech VARCHAR(50),
    category VARCHAR(100),
    difficulty_level INTEGER DEFAULT 1,
    usage_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create audio_files table
CREATE TABLE IF NOT EXISTS audio_files (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    word_id UUID REFERENCES words(id) ON DELETE CASCADE,
    file_path VARCHAR(500) NOT NULL,
    file_size INTEGER,
    duration_ms INTEGER,
    format VARCHAR(10),
    quality_score DECIMAL(3,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role VARCHAR(50) DEFAULT 'user',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create api_keys table
CREATE TABLE IF NOT EXISTS api_keys (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(100),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    tier VARCHAR(20) DEFAULT 'free',
    rate_limit_per_minute INTEGER DEFAULT 60,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- Create api_usage table
CREATE TABLE IF NOT EXISTS api_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    api_key_id UUID REFERENCES api_keys(id) ON DELETE CASCADE,
    endpoint VARCHAR(200),
    method VARCHAR(10),
    status_code INTEGER,
    response_time_ms INTEGER,
    ip_address INET,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_words_language_id ON words(language_id);
CREATE INDEX IF NOT EXISTS idx_words_category ON words(category);
CREATE INDEX IF NOT EXISTS idx_audio_files_word_id ON audio_files(word_id);
CREATE INDEX IF NOT EXISTS idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX IF NOT EXISTS idx_api_usage_created_at ON api_usage(created_at);

-- Insert sample languages
INSERT INTO languages (code, name, native_name, iso_code, region, speakers_count) VALUES
    ('swh', 'Swahili', 'Kiswahili', 'sw', 'East Africa', 150000000),
    ('yor', 'Yoruba', 'Yorùbá', 'yo', 'West Africa', 45000000),
    ('ibo', 'Igbo', 'Igbo', 'ig', 'West Africa', 24000000),
    ('hau', 'Hausa', 'Hausa', 'ha', 'West Africa', 70000000),
    ('amh', 'Amharic', 'አማርኛ', 'am', 'East Africa', 32000000)
ON CONFLICT (code) DO NOTHING;

-- Insert sample words
INSERT INTO words (language_id, word, translation, category) VALUES
    ((SELECT id FROM languages WHERE code = 'swh'), 'jambo', 'hello', 'greetings'),
    ((SELECT id FROM languages WHERE code = 'swh'), 'asante', 'thank you', 'greetings'),
    ((SELECT id FROM languages WHERE code = 'yor'), 'ẹ kú àárọ̀', 'good morning', 'greetings'),
    ((SELECT id FROM languages WHERE code = 'ibo'), 'ndewo', 'hello', 'greetings'),
    ((SELECT id FROM languages WHERE code = 'hau'), 'sannu', 'hello', 'greetings')
ON CONFLICT DO NOTHING;
EOF

print_success "Database initialization scripts created"

# =============================================================================
# STEP 6: Security Setup
# =============================================================================

print_status "Step 6: Setting up security..."

# Configure UFW firewall
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Allow development ports for testing
sudo ufw allow 3000/tcp  # Grafana
sudo ufw allow 8080/tcp  # Adminer

sudo ufw --force enable

print_success "Firewall configured"

# =============================================================================
# STEP 7: SSL Certificate Setup
# =============================================================================

print_status "Step 7: Setting up SSL certificates..."

# Create SSL directory
mkdir -p ssl

if [[ "$ENVIRONMENT" == "production" ]]; then
    print_status "Creating self-signed certificates for initial setup..."
    print_warning "You should replace these with Let's Encrypt certificates later"
fi

# Create self-signed certificates
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout ssl/privkey.pem \
    -out ssl/fullchain.pem \
    -subj "/C=US/ST=State/L=City/O=NativeLanguagesAPI/CN=$DOMAIN"

chmod 644 ssl/fullchain.pem
chmod 644 ssl/privkey.pem

print_success "SSL certificates created"

# =============================================================================
# STEP 8: Create Basic Service Templates
# =============================================================================

print_status "Step 8: Creating service templates..."

# Languages Service
mkdir -p services/languages
cat > services/languages/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001
USER nextjs

EXPOSE 3000

CMD ["npm", "start"]
EOF

cat > services/languages/package.json << 'EOF'
{
  "name": "languages-service",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "pg": "^8.11.0",
    "redis": "^4.6.7",
    "cors": "^2.8.5",
    "helmet": "^7.0.0"
  }
}
EOF

cat > services/languages/index.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'languages', timestamp: new Date() });
});

// Languages endpoint
app.get('/v1/languages', (req, res) => {
    res.json([
        { code: 'swh', name: 'Swahili', native_name: 'Kiswahili' },
        { code: 'yor', name: 'Yoruba', native_name: 'Yorùbá' },
        { code: 'ibo', name: 'Igbo', native_name: 'Igbo' },
        { code: 'hau', name: 'Hausa', native_name: 'Hausa' },
        { code: 'amh', name: 'Amharic', native_name: 'አማርኛ' }
    ]);
});

app.listen(PORT, () => {
    console.log(`Languages service running on port ${PORT}`);
});
EOF

# Audio Service
mkdir -p services/audio
cat > services/audio/Dockerfile << 'EOF'
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .

RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001
USER nextjs

EXPOSE 3001

CMD ["npm", "start"]
EOF

cat > services/audio/package.json << 'EOF'
{
  "name": "audio-service",
  "version": "1.0.0",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "multer": "^1.4.5-lts.1",
    "cors": "^2.8.5",
    "helmet": "^7.0.0"
  }
}
EOF

cat > services/audio/index.js << 'EOF'
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3001;

app.use(helmet());
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: 'audio', timestamp: new Date() });
});

app.get('/v1/audio/:lang/:word', (req, res) => {
    const { lang, word } = req.params;
    res.json({ 
        message: `Audio for ${word} in ${lang}`,
        audio_url: `https://cdn.nativetongueapis.com/audio/${lang}/${word}.mp3`
    });
});

app.listen(PORT, () => {
    console.log(`Audio service running on port ${PORT}`);
});
EOF

print_success "Service templates created"

# =============================================================================
# STEP 9: Create Management Scripts
# =============================================================================

print_status "Step 9: Creating management scripts..."

mkdir -p scripts

# Deploy script
cat > scripts/deploy.sh << 'EOF'
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
EOF

chmod +x scripts/deploy.sh

# Health check script
cat > scripts/health-check.sh << 'EOF'
#!/bin/bash

echo "Native Languages API - Health Check"
echo "==================================="

# Check services
docker-compose ps

echo ""
echo "Service Health:"

# Check if services are responding
if curl -s -f http://localhost:8000/health > /dev/null; then
    echo "✓ API Gateway: Healthy"
else
    echo "✗ API Gateway: Unhealthy"
fi

if docker-compose exec postgres pg_isready -U $DB_USER > /dev/null 2>&1; then
    echo "✓ PostgreSQL: Healthy"
else
    echo "✗ PostgreSQL: Unhealthy"
fi

if docker-compose exec redis redis-cli ping > /dev/null 2>&1; then
    echo "✓ Redis: Healthy"
else
    echo "✗ Redis: Unhealthy"
fi

echo ""
echo "System Resources:"
free -h | head -2
echo ""
df -h | head -2
EOF

chmod +x scripts/health-check.sh

print_success "Management scripts created"

# =============================================================================
# FINAL STEPS
# =============================================================================

print_success "Infrastructure setup completed successfully!"

echo ""
echo "================================================================================"
echo "🎉 NATIVE LANGUAGES API INFRASTRUCTURE SETUP COMPLETE!"
echo "================================================================================"
echo ""
echo "📁 Project Directory: $(pwd)"
echo "🌐 Domain: $DOMAIN"
echo "🔧 Environment: $ENVIRONMENT"
echo ""
echo "🚀 Next Steps:"
echo "1. Deploy the platform: ./scripts/deploy.sh"
echo "2. Check health: ./scripts/health-check.sh"
echo "3. Access Grafana: http://$(hostname -I | awk '{print $1}'):3000"
echo "4. Access Database Admin: http://$(hostname -I | awk '{print $1}'):8080"
echo ""
echo "🔐 Important:"
echo "- Grafana password: Check .env file"
echo "- Database password: Check .env file"
echo "- Replace self-signed SSL certificates with Let's Encrypt in production"
echo ""
echo "📖 Your .env file contains all passwords and configuration"
echo "================================================================================"
