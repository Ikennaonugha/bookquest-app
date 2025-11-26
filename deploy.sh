#!/bin/bash

# Book Finder Application - Deployment Script
# This script automates the deployment process to web servers

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Check if SSH key path is set, if not prompt for it
if [ -z "$SSH_KEY_PATH" ]; then
    echo -e "${YELLOW}SSH_KEY_PATH not found in .env file${NC}"
    read -p "Enter path to your SSH private key (e.g., ~/.ssh/id_rsa): " SSH_KEY_PATH
    
    # Validate that the key exists
    if [ ! -f "$SSH_KEY_PATH" ]; then
        echo -e "${RED}Error: SSH key not found at $SSH_KEY_PATH${NC}"
        exit 1
    fi
fi

# Check if SSH username is set, if not use default
if [ -z "$SSH_USER" ]; then
    echo -e "${YELLOW}SSH_USER not found in .env file${NC}"
    read -p "Enter SSH username (default: root): " SSH_USER
    SSH_USER=${SSH_USER:-root}
fi

# Display configuration
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Book Finder Deployment Script       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  SSH User: $SSH_USER"
echo "  SSH Key: $SSH_KEY_PATH"
echo "  Web01: $WEB01_IP"
echo "  Web02: $WEB02_IP"
echo ""

# Confirm before proceeding
read -p "Continue with deployment? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Deployment cancelled${NC}"
    exit 0
fi

# Function to test SSH connection
test_ssh_connection() {
    local SERVER_IP=$1
    local SERVER_NAME=$2
    
    echo -n "Testing SSH connection to $SERVER_NAME... "
    
    if ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=5 -o BatchMode=yes "$SSH_USER@$SERVER_IP" "exit" 2>/dev/null; then
        echo -e "${GREEN}✓ Success${NC}"
        return 0
    else
        echo -e "${RED}✗ Failed${NC}"
        return 1
    fi
}

# Function to deploy to a server
deploy_to_server() {
    local SERVER_IP=$1
    local SERVER_NAME=$2
    
    echo ""
    echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Deploying to ${SERVER_NAME}                  ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
    
    # Create temporary directory for deployment files
    TEMP_DIR=$(mktemp -d)
    
    echo "📁 Preparing deployment files..."
    
    # Copy files to temp directory
    cp index.html "$TEMP_DIR/" 2>/dev/null || { echo -e "${RED}Error: index.html not found${NC}"; return 1; }
    cp app.js "$TEMP_DIR/" 2>/dev/null || { echo -e "${RED}Error: app.js not found${NC}"; return 1; }
    
    # Check if config.js exists, if not create from example
    if [ -f "config.js" ]; then
        cp config.js "$TEMP_DIR/"
    else
        echo -e "${YELLOW}⚠ config.js not found, creating from config.example.js${NC}"
        if [ -f "config.example.js" ]; then
            cp config.example.js "$TEMP_DIR/config.js"
            echo -e "${YELLOW}⚠ Remember to add your API key to config.js on the server${NC}"
        else
            echo -e "${RED}Error: Neither config.js nor config.example.js found${NC}"
            rm -rf "$TEMP_DIR"
            return 1
        fi
    fi
    
    # If config.js still has placeholder, try to use API key from .env
    if grep -q "YOUR_API_KEY_HERE" "$TEMP_DIR/config.js" 2>/dev/null; then
        if [ ! -z "$GOOGLE_BOOKS_API_KEY" ]; then
            echo "🔑 Injecting API key from .env file..."
            sed -i.bak "s/YOUR_API_KEY_HERE/${GOOGLE_BOOKS_API_KEY}/" "$TEMP_DIR/config.js"
            rm -f "$TEMP_DIR/config.js.bak"
        else
            echo -e "${YELLOW}⚠ Warning: config.js has placeholder API key${NC}"
        fi
    fi
    
    echo "📡 Connecting to $SERVER_NAME ($SERVER_IP)..."
    
    # Create application directory on server
    ssh -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" "mkdir -p /var/www/book-finder" || {
        echo -e "${RED}✗ Failed to create directory on server${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    }
    
    echo "📤 Uploading files to $SERVER_NAME..."
    
    # Copy files to server using SSH key
    scp -i "$SSH_KEY_PATH" -r "$TEMP_DIR"/* "$SSH_USER@$SERVER_IP:/var/www/book-finder/" || {
        echo -e "${RED}✗ Failed to copy files to server${NC}"
        rm -rf "$TEMP_DIR"
        return 1
    }
    
    echo "🔐 Setting permissions..."
    
    # Set proper permissions
    ssh -i "$SSH_KEY_PATH" "$SSH_USER@$SERVER_IP" "chown -R www-data:www-data /var/www/book-finder && chmod -R 755 /var/www/book-finder" || {
        echo -e "${YELLOW}⚠ Warning: Could not set permissions (may need to run manually)${NC}"
    }
    
    # Clean up temp directory
    rm -rf "$TEMP_DIR"
    
    echo -e "${GREEN}✓ Deployment to ${SERVER_NAME} completed successfully!${NC}"
    return 0
}

# Main deployment process
echo ""
echo -e "${GREEN}Starting Deployment Process...${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Test SSH connections first
echo ""
echo "Testing SSH connections..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test_ssh_connection "$WEB01_IP" "Web01"
WEB01_SSH=$?

test_ssh_connection "$WEB02_IP" "Web02"
WEB02_SSH=$?

if [ $WEB01_SSH -ne 0 ] && [ $WEB02_SSH -ne 0 ]; then
    echo -e "${RED}Error: Cannot connect to any servers. Please check:${NC}"
    echo "  1. SSH key path is correct: $SSH_KEY_PATH"
    echo "  2. SSH key has correct permissions: chmod 600 $SSH_KEY_PATH"
    echo "  3. Server IPs are correct"
    echo "  4. Servers are online and accessible"
    exit 1
fi

# Deploy to servers
DEPLOYMENT_SUCCESS=0

if [ $WEB01_SSH -eq 0 ]; then
    deploy_to_server "$WEB01_IP" "Web01"
    if [ $? -eq 0 ]; then
        ((DEPLOYMENT_SUCCESS++))
    fi
else
    echo -e "${RED}✗ Skipping Web01 (SSH connection failed)${NC}"
fi

if [ $WEB02_SSH -eq 0 ]; then
    deploy_to_server "$WEB02_IP" "Web02"
    if [ $? -eq 0 ]; then
        ((DEPLOYMENT_SUCCESS++))
    fi
else
    echo -e "${RED}✗ Skipping Web02 (SSH connection failed)${NC}"
fi

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $DEPLOYMENT_SUCCESS -eq 2 ]; then
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   ✓ DEPLOYMENT SUCCESSFUL!            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Both servers deployed successfully!${NC}"
elif [ $DEPLOYMENT_SUCCESS -eq 1 ]; then
    echo -e "${YELLOW}╔════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║   ⚠ PARTIAL DEPLOYMENT               ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}Only one server deployed successfully${NC}"
else
    echo -e "${RED}╔════════════════════════════════════════╗${NC}"
    echo -e "${RED}║   ✗ DEPLOYMENT FAILED                 ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${RED}Deployment failed on all servers${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Next Steps:${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Configure Nginx on both web servers (if not already done)"
echo "2. Configure HAProxy on the load balancer"
echo "3. Test the application:"
if [ $WEB01_SSH -eq 0 ]; then
    echo "   - Web01: http://${WEB01_IP}"
fi
if [ $WEB02_SSH -eq 0 ]; then
    echo "   - Web02: http://${WEB02_IP}"
fi
if [ ! -z "$LB01_IP" ]; then
    echo "   - Load Balancer: http://${LB01_IP}"
fi
echo ""
echo "4. Run test script: ./test-deployment.sh"
echo ""
echo -e "${GREEN}Deployment process completed!${NC}"
echo ""
