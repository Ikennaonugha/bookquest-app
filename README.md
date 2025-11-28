# Bookquest Application

A web-based book search application that uses the Google Books API to search and display millions of books with advanced filtering and sorting capabilities.
![Bookquest Application](https://img.shields.io/badge/API-Google%20Books-blue) ![License](https://img.shields.io/badge/license-MIT-green)

Link to video: https://youtu.be/w8xuugNG9PY

Link to web application: http://54.165.38.33/
## Features

- 🔍 **Real-time Search**: Search books by title, author, ISBN, or keywords
- 📂 **Advanced Filtering**: Filter by category (Fiction, Science, History, Biography, etc.)
- 🔄 **Sorting Options**: Sort results by relevance or publication date
- 📚 **Rich Book Information**: Display book covers, descriptions, authors, and publication dates
- 🔗 **Direct Links**: Links to Google Books for detailed information
- 📱 **Responsive Design**: Works seamlessly on desktop, tablet, and mobile devices
- ⚠️ **Error Handling**: Graceful handling of API errors, network issues, and invalid inputs
- 🔒 **Secure API Key Management**: API keys stored separately and excluded from version control

## Technology Stack

- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **API**: Google Books API v1 (with API key authentication)
- **Web Server**: Nginx
- **Load Balancer**: HAProxy
- **Deployment**: Shell script automation

## Project Structure

```
bookquest-app/
├── index.html              # Main HTML file
├── app.js                  # Application logic
├── config.js               # Configuration file
├── config.example.js       # Configuration template
├── .env                    # Environment variables 
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore file
├── deploy.sh               # Deployment script
└── README.md               # This file
```

## Prerequisites

### For Local Development:
- Web browser (Chrome, Firefox, Safari, or Edge)
- Google Books API key
- Python 3.x (for local server) OR any HTTP server

### For Deployment:
- SSH access to three servers:
  - Web01 (Ubuntu/Debian)
  - Web02 (Ubuntu/Debian)
  - Lb01 (Load Balancer)
- Root or sudo access on all servers

## Local Setup

### Step 1: Clone the Repository

```bash
git clone the url
cd bookquest-app
```

### Step 2: Create Configuration Files

1. **Copy the example files and replace with your key and IP of your web server:**
```bash
cp config.example.js config.js
cp .env.example .env
```

## API Key Setup

### Getting Your Google Books API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Books API**:
   - Navigate to "APIs & Services" > "Library"
   - Search for "Books API"
   - Click "Enable"
4. Create credentials:
   - Go to "APIs & Services" > "Credentials"
   - Click "Create Credentials" > "API Key"
   - Copy your API key

### Configuring Your API Key

**Option 1: Using config.js (Recommended for this project)**

Edit `config.js` and replace `YOUR_API_KEY_HERE` with your actual API key:

```javascript
const CONFIG = {
    API_KEY: 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX', // Your actual key
    API_BASE_URL: 'https://www.googleapis.com/books/v1/volumes',
    MAX_RESULTS: 40,
    DEFAULT_SORT: 'relevance',
};
```

**Option 2: Using .env file (For deployment automation)**

Edit `.env` and add your API key:

```bash
GOOGLE_BOOKS_API_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
WEB01_IP=your_web01_ip
WEB02_IP=your_web02_ip
LB01_IP=your_load_balancer_ip
```

**⚠️ CRITICAL SECURITY NOTICE:**
- NEVER commit `config.js` or `.env` files to version control
- The `.gitignore` file is configured to prevent this
- Always verify before committing: `git status`
- Only commit `config.example.js` and `.env.example`

## Running Locally

### Method 1: Python HTTP Server (Recommended)

```bash
# Navigate to project directory
cd bookquest-app

# Start server on port 8000
python3 -m http.server 8000

# Open browser to:
# http://localhost:8000
```

### Method 2: Node.js HTTP Server

```bash
# Install http-server globally (one time)
npm install -g http-server

# Run server
http-server -p 8000

# Open browser to:
# http://localhost:8000
```

## Deployment

### Automated Deployment (Recommended)

1. **Configure your .env file** with server IPs and API key
2. **Make deployment script executable:**
```bash
chmod +x deploy.sh
```
3. **Run deployment:**
```bash
./deploy.sh
```

### Manual Deployment

#### Step 1: Deploy to Web Servers (Web01 & Web02)

**On both Web01 and Web02:**

1. **Install Nginx:**
```bash
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
```

2. **Create application directory:**
```bash
sudo mkdir -p /var/www/bookquest-app
```

3. **Copy application files:**
```bash
# Copy index.html
sudo nano /var/www/bookquest-app/index.html
# Paste content

# Copy app.js
sudo nano /var/www/bookquest-app/app.js
# Paste content

# Create config.js with your API key
sudo nano /var/www/bookquest-app/config.js
# Paste config with YOUR ACTUAL API KEY
```

4. **Set permissions:**
```bash
sudo chown -R www-data:www-data /var/www/bookquest-app
sudo chmod -R 755 /var/www/bookquest-app
```

5. **Configure Nginx:**
```bash
sudo nano /etc/nginx/sites-available/bookquest-app
```

Add this configuration:
```nginx
server {
    listen 80;
    server_name _;

    root /var/www/bookquest-app;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }

    # Add server identifier for testing
    add_header X-Served-By $hostname;

    # Security headers
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Enable gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/css application/javascript application/json;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
```

6. **Enable site:**
```bash
sudo ln -s /etc/nginx/sites-available/bookquest-app /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl reload nginx
```

7. **Configure firewall:**
```bash
sudo ufw allow 'Nginx HTTP'
sudo ufw enable
```

#### Step 2: Configure Load Balancer (Lb01)

1. **Install HAProxy:**
```bash
sudo apt update
sudo apt install haproxy -y
```

2. **Backup original config:**
```bash
sudo cp /etc/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg.backup
```

3. **Configure HAProxy:**
```bash
sudo nano /etc/haproxy/haproxy.cfg
```

Replace with:
```
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s
    user haproxy
    group haproxy
    daemon
    maxconn 2000

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5000
    timeout client  50000
    timeout server  50000
    errorfile 400 /etc/haproxy/errors/400.http
    errorfile 403 /etc/haproxy/errors/403.http
    errorfile 408 /etc/haproxy/errors/408.http
    errorfile 500 /etc/haproxy/errors/500.http
    errorfile 502 /etc/haproxy/errors/502.http
    errorfile 503 /etc/haproxy/errors/503.http
    errorfile 504 /etc/haproxy/errors/504.http

frontend book_finder_frontend
    bind *:80
    default_backend book_finder_backend
    
    # Security headers
    http-response set-header X-Content-Type-Options nosniff
    http-response set-header X-Frame-Options DENY
    http-response set-header X-XSS-Protection "1; mode=block"

backend book_finder_backend
    balance roundrobin
    option httpchk GET /
    http-check expect status 200
    
    # Backend servers
    server web01 <WEB01_IP>:80 check inter 2000 rise 2 fall 3
    server web02 <WEB02_IP>:80 check inter 2000 rise 2 fall 3

# Statistics interface
listen stats
    bind *:8080
    stats enable
    stats uri /haproxy?stats
    stats realm HAProxy\ Statistics
    stats refresh 30s
    stats show-node
    stats show-legends
```

**Replace `<WEB01_IP>` and `<WEB02_IP>` with your actual server IPs.**

4. **Enable and start HAProxy:**
```bash
sudo systemctl enable haproxy
sudo systemctl start haproxy
sudo systemctl status haproxy
```

5. **Configure firewall:**
```bash
sudo ufw allow 80/tcp
sudo ufw allow 8080/tcp
sudo ufw enable
```

## Testing

### Test Web Servers Individually

```bash
# Test Web01
curl -I http://<WEB01_IP>

# Test Web02
curl -I http://<WEB02_IP>

# Both should return HTTP/1.1 200 OK
```

### Test Load Balancer

```bash
# Basic connectivity test
curl -I http://<LB01_IP>

# Check which server is responding (run multiple times)
for i in {1..10}; do
    curl -s -I http://<LB01_IP> | grep "X-Served-By"
done

# You should see responses alternating between web01 and web02
```

### Test in Browser

1. **Access the application:**
   ```
   http://<LB01_IP>
   ```

2. **Test search functionality:**
   - Enter a search term (e.g., "JavaScript")
   - Try different filters and sorting options
   - Verify book information displays correctly

3. **View HAProxy statistics:**
   ```
   http://<LB01_IP>:8080/haproxy?stats
   ```
   - Check that both servers show as "UP"
   - Monitor request distribution

### Test High Availability

```bash
# Stop one web server
ssh web01
sudo systemctl stop nginx

# Application should still work via load balancer
curl http://<LB01_IP>

# Restart the server
sudo systemctl start nginx

# Stop the other server
ssh web02
sudo systemctl stop nginx

# Application should still work
curl http://<LB01_IP>

# Restart
sudo systemctl start nginx
```

### Test Application Features

1. **Search functionality:**
   - Search: "Python programming"
   - Verify results appear

2. **Filtering:**
   - Apply category filter: "Technology"
   - Verify filtered results

3. **Sorting:**
   - Change sort to "Newest First"
   - Verify order changes

4. **Error handling:**
   - Search with empty input
   - Verify error message appears
   - Search for nonsense term
   - Verify "no results" message

## Troubleshooting
**Problem:** "API key is invalid" error

**Solutions:**
1. Verify key is copied correctly (no extra spaces)
2. Check if Books API is enabled in Google Cloud Console
3. Check API key restrictions
4. Check quota limits

### Nginx Issues

```bash
# Check Nginx status
sudo systemctl status nginx

# View error logs
sudo tail -f /var/log/nginx/error.log

# Test configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Check if port 80 is in use
sudo netstat -tlnp | grep :80
```

### HAProxy Issues

```bash
# Check HAProxy status
sudo systemctl status haproxy

# Test configuration
sudo haproxy -c -f /etc/haproxy/haproxy.cfg

# View logs
sudo tail -f /var/log/haproxy.log

# Restart HAProxy
sudo systemctl restart haproxy

# Check backend status
echo "show stat" | sudo socat stdio /run/haproxy/admin.sock
```

### Network Issues

```bash
# Test connectivity between servers
ping <WEB01_IP>
ping <WEB02_IP>

# Check firewall rules
sudo ufw status numbered

# Test port accessibility
telnet <WEB01_IP> 80
nc -zv <WEB01_IP> 80
```

### Browser Console Errors

1. Open browser developer tools (F12)
2. Check Console tab for JavaScript errors
3. Check Network tab for failed API requests
4. Common issues:
   - CORS errors (usually not a problem with Google Books API)
   - 403 errors (invalid API key)
   - Network timeout (connectivity issue)

## API Rate Limits

Google Books API (with API key):
- **Requests per day**: 1,000 (free tier)
- **Requests per 100 seconds**: 100
- **Requests per second**: 10
## Credits

- **API Provider**: [Google Books API](https://developers.google.com/books)
- **Load Balancer**: [HAProxy](http://www.haproxy.org/)
- **Web Server**: [Nginx](https://nginx.org/)
- **Icons**: Unicode emoji characters

## Development Challenges

### Challenges Encountered:

1. **API Key Management**
   - **Challenge**: Securely storing API keys without committing to git
   - **Solution**: Implemented separate config files with `.gitignore`

2. **Load Balancing**
   - **Challenge**: Ensuring even distribution of requests
   - **Solution**: Configured HAProxy with round-robin and health checks

3. **Error Handling**
   - **Challenge**: Graceful handling of various API errors
   - **Solution**: Implemented try-catch blocks with specific error messages

4. **Responsive Design**
   - **Challenge**: Working on different screen sizes
   - **Solution**: CSS Grid with responsive breakpoints

## License

This project is created for educational purposes as part of a web development assignment.

## Author

Ikenna Onugha 
i.onugha@alustudent.com
Ikennaonugha




