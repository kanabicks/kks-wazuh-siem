#!/bin/bash

# KKS Wazuh SIEM - Automated Setup Script
# https://github.com/kanabicks/kks-wazuh-siem

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════╗
║   🛡️  KKS Wazuh SIEM Setup Script        ║
║   Automated deployment for CTF & SecOps  ║
╚═══════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Function to print status messages
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# 1. System Requirements Check (Non-blocking)
echo ""
print_info "Step 1/7: Checking system requirements..."

# Check RAM (non-blocking)
TOTAL_RAM=$(free -g 2>/dev/null | awk '/^Mem:/{print $2}' || echo "unknown")
if [ "$TOTAL_RAM" != "unknown" ]; then
    if [ "$TOTAL_RAM" -lt 8 ]; then
        print_warning "RAM: ${TOTAL_RAM}GB detected (8GB+ recommended for stable operation)"
    else
        print_status "RAM: ${TOTAL_RAM}GB"
    fi
else
    print_warning "Could not detect RAM. Minimum 8GB recommended."
fi

# Check CPU (non-blocking)
CPU_CORES=$(nproc 2>/dev/null || echo "unknown")
if [ "$CPU_CORES" != "unknown" ]; then
    if [ "$CPU_CORES" -lt 4 ]; then
        print_warning "CPU: ${CPU_CORES} cores detected (4+ recommended for stable operation)"
    else
        print_status "CPU: ${CPU_CORES} cores"
    fi
else
    print_warning "Could not detect CPU cores. Minimum 4 cores recommended."
fi

# Check disk space (non-blocking)
DISK_SPACE=$(df -BG / 2>/dev/null | awk 'NR==2 {print $4}' | sed 's/G//' || echo "unknown")
if [ "$DISK_SPACE" != "unknown" ]; then
    if [ "$DISK_SPACE" -lt 50 ]; then
        print_warning "Disk space: ${DISK_SPACE}GB available (50GB+ recommended)"
    else
        print_status "Disk space: ${DISK_SPACE}GB available"
    fi
else
    print_warning "Could not detect disk space. Minimum 50GB recommended."
fi

# Display requirements summary
echo ""
print_info "Minimum recommended requirements:"
echo "   - RAM: 8GB+"
echo "   - CPU: 4 cores+"
echo "   - Disk: 50GB+ free space"
echo "   - Docker: 20.10+"
echo "   - Docker Compose: 2.0+"
print_warning "If your system doesn't meet these requirements, stability issues may occur."
echo ""

# Check Docker (REQUIRED)
if ! command -v docker &> /dev/null; then
    print_error "Docker not found! Install: sudo apt install docker.io"
    exit 1
fi
DOCKER_VERSION=$(docker --version 2>/dev/null | awk '{print $3}' | sed 's/,//' || echo "unknown")
print_status "Docker: ${DOCKER_VERSION}"

# Check Docker Compose (REQUIRED)
if ! command -v docker &> /dev/null || ! docker compose version &> /dev/null; then
    print_error "Docker Compose not found! Install: sudo apt install docker-compose-plugin"
    exit 1
fi
COMPOSE_VERSION=$(docker compose version 2>/dev/null | awk '{print $4}' | sed 's/,//' || echo "unknown")
print_status "Docker Compose: ${COMPOSE_VERSION}"

# Check if running as root (ALLOWED)
if [[ $EUID -eq 0 ]]; then
    print_warning "Running as root. This is allowed but not recommended for production."
    RUNNING_AS_ROOT=true
else
    RUNNING_AS_ROOT=false
    
    # Check if user is in docker group
    if ! groups | grep -q docker; then
        print_warning "Current user not in 'docker' group. Adding..."
        sudo usermod -aG docker $USER
        print_warning "Please logout and login again, then re-run this script"
        print_info "Or run: newgrp docker && ./setup.sh"
        exit 0
    fi
fi

# 2. Install additional tools if needed
echo ""
print_info "Step 2/7: Installing required tools..."

MISSING_TOOLS=()

if ! command -v htpasswd &> /dev/null; then
    MISSING_TOOLS+=("apache2-utils")
fi

if ! command -v openssl &> /dev/null; then
    MISSING_TOOLS+=("openssl")
fi

if ! command -v curl &> /dev/null; then
    MISSING_TOOLS+=("curl")
fi

if [ ${#MISSING_TOOLS[@]} -gt 0 ]; then
    print_info "Installing: ${MISSING_TOOLS[*]}"
    if [[ $RUNNING_AS_ROOT == true ]]; then
        apt update -qq
        apt install -y "${MISSING_TOOLS[@]}"
    else
        sudo apt update -qq
        sudo apt install -y "${MISSING_TOOLS[@]}"
    fi
    print_status "Tools installed"
else
    print_status "All tools already installed"
fi

# 3. Generate passwords
echo ""
print_info "Step 3/7: Generating secure passwords..."

generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

if [ -f .env ]; then
    print_warning ".env file already exists"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Using existing .env file"
    else
        rm .env
    fi
fi

if [ ! -f .env ]; then
    if [ ! -f .env.example ]; then
        print_error ".env.example not found! Please clone the repository properly."
        exit 1
    fi
    
    cp .env.example .env
    
    WAZUH_ADMIN_PASS=$(generate_password)
    INDEXER_PASS=$(generate_password)
    DASHBOARD_PASS=$(generate_password)
    API_PASS=$(generate_password)
    
    sed -i "s/WAZUH_ADMIN_PASSWORD=.*/WAZUH_ADMIN_PASSWORD=${WAZUH_ADMIN_PASS}/" .env
    sed -i "s/INDEXER_PASSWORD=.*/INDEXER_PASSWORD=${INDEXER_PASS}/" .env
    sed -i "s/DASHBOARD_PASSWORD=.*/DASHBOARD_PASSWORD=${DASHBOARD_PASS}/" .env
    sed -i "s/API_PASSWORD=.*/API_PASSWORD=${API_PASS}/" .env
    
    print_status "Passwords generated and saved to .env"
else
    print_status "Using existing .env configuration"
fi

# 4. Generate Nginx credentials
echo ""
print_info "Step 4/7: Configuring Nginx authentication..."

# Create nginx_conf directory if it doesn't exist
if [ ! -d nginx_conf ]; then
    print_warning "nginx_conf directory not found. Creating..."
    mkdir -p nginx_conf
fi

if [ -f nginx_conf/.htpasswd ]; then
    print_warning "nginx_conf/.htpasswd already exists"
    read -p "Overwrite? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm nginx_conf/.htpasswd
    fi
fi

if [ ! -f nginx_conf/.htpasswd ]; then
    echo ""
    print_info "Create Nginx Basic Auth credentials for web access"
    read -p "Username [admin]: " NGINX_USER
    NGINX_USER=${NGINX_USER:-admin}
    
    htpasswd -c nginx_conf/.htpasswd "$NGINX_USER"
    
    # Update .env
    sed -i "s/NGINX_USER=.*/NGINX_USER=${NGINX_USER}/" .env
    
    print_status "Nginx credentials created"
else
    print_status "Using existing Nginx credentials"
fi

# 5. Generate SSL Certificates
echo ""
print_info "Step 5/7: Generating SSL certificates..."

if [ -d certs ] && [ "$(ls -A certs 2>/dev/null | grep -v '.gitkeep')" ]; then
    print_warning "Certificates directory already exists with files"
    read -p "Regenerate certificates? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        find certs -type f ! -name '.gitkeep' -delete
    else
        print_status "Using existing certificates"
    fi
fi

# Check if we need to generate certificates
NEEDS_CERTS=false
if [ ! -d certs ]; then
    NEEDS_CERTS=true
elif [ -z "$(ls -A certs 2>/dev/null | grep -v '.gitkeep')" ]; then
    NEEDS_CERTS=true
fi

if [ "$NEEDS_CERTS" = true ]; then
    mkdir -p certs
    cd certs
    
    print_info "Generating Root CA..."
    openssl genrsa -out root-ca-key.pem 2048 2>/dev/null
    openssl req -new -x509 -sha256 -key root-ca-key.pem -subj "/C=RU/ST=Moscow/L=Moscow/O=KKS/OU=Security/CN=KKS-Root-CA" -out root-ca.pem -days 730 2>/dev/null
    
    print_info "Generating Admin certificate..."
    openssl genrsa -out admin-key-temp.pem 2048 2>/dev/null
    openssl pkcs8 -inform PEM -outform PEM -in admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out admin-key.pem 2>/dev/null
    openssl req -new -key admin-key.pem -subj "/C=RU/ST=Moscow/L=Moscow/O=KKS/OU=Security/CN=admin" -out admin.csr 2>/dev/null
    openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out admin.pem -days 730 2>/dev/null
    
    print_info "Generating Indexer certificate..."
    openssl genrsa -out wazuh.indexer-key-temp.pem 2048 2>/dev/null
    openssl pkcs8 -inform PEM -outform PEM -in wazuh.indexer-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out wazuh.indexer-key.pem 2>/dev/null
    openssl req -new -key wazuh.indexer-key.pem -subj "/C=RU/ST=Moscow/L=Moscow/O=KKS/OU=Security/CN=wazuh.indexer" -out wazuh.indexer.csr 2>/dev/null
    echo "subjectAltName=DNS:wazuh.indexer,IP:172.18.0.3" > wazuh.indexer.ext
    openssl x509 -req -in wazuh.indexer.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out wazuh.indexer.pem -days 730 -extfile wazuh.indexer.ext 2>/dev/null
    
    print_info "Generating Manager certificate..."
    openssl genrsa -out wazuh.manager-key-temp.pem 2048 2>/dev/null
    openssl pkcs8 -inform PEM -outform PEM -in wazuh.manager-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out wazuh.manager-key.pem 2>/dev/null
    openssl req -new -key wazuh.manager-key.pem -subj "/C=RU/ST=Moscow/L=Moscow/O=KKS/OU=Security/CN=wazuh.manager" -out wazuh.manager.csr 2>/dev/null
    openssl x509 -req -in wazuh.manager.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out wazuh.manager.pem -days 730 2>/dev/null
    
    print_info "Generating Dashboard certificate..."
    openssl genrsa -out wazuh.dashboard-key-temp.pem 2048 2>/dev/null
    openssl pkcs8 -inform PEM -outform PEM -in wazuh.dashboard-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out wazuh.dashboard-key.pem 2>/dev/null
    openssl req -new -key wazuh.dashboard-key.pem -subj "/C=RU/ST=Moscow/L=Moscow/O=KKS/OU=Security/CN=wazuh.dashboard" -out wazuh.dashboard.csr 2>/dev/null
    openssl x509 -req -in wazuh.dashboard.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out wazuh.dashboard.pem -days 730 2>/dev/null
    
    # Cleanup temporary files
    rm -f *.csr *.srl *-temp.pem *.ext
    
    # Create symlinks for Nginx (uses wazuh.dashboard certs)
    print_info "Creating symlinks for Nginx..."
    ln -sf wazuh.dashboard.pem nginx.crt
    ln -sf wazuh.dashboard-key.pem nginx.key
    
    cd ..
    print_status "SSL certificates generated in ./certs/"
fi

# 6. Start Docker Compose
echo ""
print_info "Step 6/7: Starting Wazuh SIEM stack..."

# Check if docker-compose.yml exists
if [ ! -f docker-compose.yml ]; then
    print_error "docker-compose.yml not found! Please clone the repository properly."
    exit 1
fi

# Pull images first
print_info "Pulling Docker images (this may take a few minutes)..."
docker compose pull

# Start services
print_info "Starting containers..."
docker compose up -d

print_status "Containers started"

# 7. Health check
echo ""
print_info "Step 7/7: Waiting for services to initialize..."

print_info "This may take 2-3 minutes. Please wait..."
echo ""

# Wait for indexer
INDEXER_READY=false
print_info "Waiting for Wazuh Indexer to start..."
for i in {1..60}; do
    if docker compose logs wazuh.indexer 2>/dev/null | grep -q "started"; then
        INDEXER_READY=true
        break
    fi
    sleep 3
    echo -n "."
done
echo ""

if [ "$INDEXER_READY" = true ]; then
    print_status "Wazuh Indexer is ready"
else
    print_warning "Wazuh Indexer is still initializing (check logs with: docker compose logs wazuh.indexer)"
fi

# Wait for manager
sleep 10
if docker compose ps wazuh.manager 2>/dev/null | grep -q "Up"; then
    print_status "Wazuh Manager is running"
else
    print_warning "Wazuh Manager may still be starting (check logs with: docker compose logs wazuh.manager)"
fi

# Final status check
echo ""
print_info "Checking service status..."
docker compose ps

# 8. Success message
echo ""
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════╗
║         ✅ Wazuh SIEM Setup Complete!             ║
╚═══════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Get credentials
DASHBOARD_PASS=$(grep DASHBOARD_PASSWORD .env 2>/dev/null | cut -d '=' -f2 || echo "<check .env file>")
NGINX_USER=$(grep NGINX_USER .env 2>/dev/null | cut -d '=' -f2 || echo "admin")

echo ""
print_status "Access Information:"
echo ""
echo -e "${BLUE}🌐 Wazuh Dashboard:${NC}"
echo "   URL:      https://localhost:443"
echo "   Username: ${NGINX_USER}"
echo "   Password: <your htpasswd password>"
echo ""
echo -e "${BLUE}🔐 Dashboard Login (after basic auth):${NC}"
echo "   Username: admin"
echo "   Password: ${DASHBOARD_PASS}"
echo ""
echo -e "${BLUE}📊 OpenSearch API:${NC}"
echo "   URL: http://localhost:9200"
echo ""
echo -e "${BLUE}🔍 Wazuh API:${NC}"
echo "   URL: https://localhost:55000"
echo ""

print_info "Useful commands:"
echo "   docker compose logs -f             # View all logs"
echo "   docker compose ps                  # Check status"
echo "   docker compose restart wazuh.manager  # Restart service"
echo "   docker compose down                # Stop all services"
echo ""

print_warning "Services may take 2-3 minutes to fully initialize"
print_info "Monitor logs: docker compose logs -f wazuh.manager"
echo ""

if [[ $RUNNING_AS_ROOT == true ]]; then
    print_warning "You are running as root. For production, consider running as a non-root user."
fi

echo -e "${GREEN}🎉 Happy hunting!${NC}"
