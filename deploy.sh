#!/bin/bash

# Book Finder Application - Deployment Script
# This script automates the deployment process to web servers

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    source .env
else
    echo -e "${RED}Error: .env file not found. Please create it from .env.example${NC}"
    exit 1
fi

# Check if required variables are set
if [ -z "$WEB01_IP" ] || [ -z "$WEB02_IP" ]; then
    echo -e "${RED}Error: Server IPs not configured in .env file${NC}"
    exit 1
fi

# Function to deploy to a server
deploy_to_server() {
    local SERVER_IP=$1
    local SERVER_NAME=$2
    
    echo -e "${YELLOW}Deploying to ${SERVER_NAME} (${SERVER_IP})...${NC}"
    
    # Create temporary directory for deployment files
    TEMP_DIR=$(mktemp -d)
    
    # Copy files to temp directory
    cp index.html "$TEMP_DIR/"
    cp app.js "$TEMP_DIR/"
    
    # Create config.js with API key for deployment
    cat > "$TEMP_DIR/config.js" << EOF
const CONFIG = {
    API_KEY: '${GOOGLE_BOOKS_API_KEY}',
    API_BASE_URL: 'https://www.googleapis.com/books/v1/volumes',
    MAX_RESULTS: 40,
    DEFAULT_SORT: 'relevance',
};
EOF
    
    # Create application directory on server
    ssh root@${SERVER_IP} "mkdir -p /var/www/book-finder"
    
    # Copy files to server
    scp -r "$TEMP_DIR"/* root@${SERVER_IP}:/var/www/book-finder/
    
    # Set proper permissions
    ssh root@${SERVER_IP} "chown -R www-data:www-data /var/www/book-finder && chmod -R 755 /var/www/book-finder"
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}✓ Deployment to ${SERVER_NAME} completed${NC}"
}

# Main deployment process
echo -e "${GREEN}Starting Book Finder Application Deployment${NC}"
echo "==========================================="

# Deploy to Web01
deploy_to_server "$WEB01_IP" "Web01"

# Deploy to Web02
deploy_to_server "$WEB02_IP" "Web02"

echo ""
echo -e "${GREEN}==========================================="
echo "Deployment completed successfully!"
echo "==========================================="
echo -e "${NC}"
echo "Next steps:"
echo "1. Configure Nginx on both web servers"
echo "2. Configure HAProxy on the load balancer"
echo "3. Test the application"
echo ""
echo "Access your application at: http://${LB01_IP}"