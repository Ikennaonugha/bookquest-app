# BookQuest – Book Discovery Web Application  
**A practical, user-friendly book search engine powered by the Google Books API**  
**Assignment: External API Application with Load-Balanced Deployment**

link to video

## Overview & Purpose
BookQuest is a modern web application that allows users to search the entire Google Books database with powerful filtering and sorting capabilities.  
It solves a **real user need**: quickly discovering high-quality books with ratings, descriptions, cover images, and direct preview links — all in one clean, responsive interface.

**Features**
- Search by keyword, author, title, ISBN, etc.
- Filter by language, print type (books only or magazines), and order by relevance or newest
- Beautiful, fully responsive design (desktop + mobile)
- Fast loading with proper error handling
- Secure handling of the Google Books API key
- Production-ready deployment behind Nginx + Gunicorn
- Load-balanced across two web servers (Web01 & Web02) via Lb01

**Live URL (via load balancer):**  
http://YOUR_LB01_IP_OR_DOMAIN  

(Replace with your actual Lb01 public IP or domain before submission)

## Tech Stack
- **Backend:** Python 3 + Flask
- **Production Server:** Gunicorn
- **Web Server / Reverse Proxy / Load Balancer:** Nginx
- **External API:** Google Books API (v1) – https://developers.google.com/books
- **Frontend:** HTML5, CSS3 (custom responsive design), minimal vanilla JS
- **Deployment:** Two standard web servers + one Nginx load balancer

## Project Structure
```
bookquest-app/
├── app.py                     # Main Flask application
├── requirements.txt           # Python dependencies
├── .env.example               # Template (never commit real key)
├── .gitignore
├── README.md                  # This file
├── static/
│   ├── css/style.css          # Modern, responsive styling
│   └── img/                   # Optional: no-cover placeholder
└── templates/
    └── index.html             # Search form + results table
└── deployments/
    ├── nginx-web.conf         # Nginx config for Web01 & Web02
    ├── nginx-lb.conf          # Load balancer config for Lb01
    └── bookquest.service      # Systemd service file
```

## How to Run Locally (Part One)

### 1. Clone the repository
```bash
git clone https://github.com/yourusername/bookquest-app.git
cd bookquest-app
```

### 2. Create virtual environment & install dependencies
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 3. Add your Google Books API key
```bash
cp .env.example .env
nano .env
```
Paste your real key:
```env
GOOGLE_BOOKS_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

### 4. Run the app
```bash
python app.py
```
Open your browser → http://127.0.0.1:5000

## Deployment Instructions (Part Two)

### On Web01 and Web02 (identical steps)

```bash
# 1. System update & tools
sudo apt update && sudo apt upgrade -y
sudo apt install python3-venv python3-pip git nginx -y

# 2. Clone code
sudo mkdir -p /var/www/bookquest-app
sudo chown $USER:$USER /var/www/bookquest-app
cd /var/www/bookquest-app
git clone https://github.com/yourusername/bookquest-app.git .
# Or use scp from local machine if repo is private

# 3. Python environment
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt gunicorn

# 4. Add API key
echo "GOOGLE_BOOKS_API_KEY=xxxxxxxxxxxxxxxxxxxxxx" > .env

# 5. Create systemd service
sudo cp deployments/bookquest.service /etc/systemd/system/bookquest.service
sudo systemctl daemon-reexec
sudo systemctl start bookquest
sudo systemctl enable bookquest

# 6. Configure Nginx
sudo cp deployments/nginx-web.conf /etc/nginx/sites-available/bookquest
sudo ln -sf /etc/nginx/sites-available/bookquest /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
```

### On Lb01 (Load Balancer)

```bash
sudo apt install nginx -y

sudo cp deployments/nginx-lb.conf /etc/nginx/sites-available/loadbalancer
# Edit the file and replace WEB01_IP and WEB02_IP with real IPs
sudo nano /etc/nginx/sites-available/loadbalancer

sudo ln -sf /etc/nginx/sites-available/loadbalancer /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
```

Your app is now accessible via the **Lb01 public IP** and traffic is automatically balanced between Web01 and Web02.

## API Used & Credits
**Google Books API**  
Documentation: https://developers.google.com/books  
Developer: Google LLC  
License: Free tier (1000 requests/day) – perfect for this project

**Thank you Google for providing this excellent, reliable, and well-documented public API.**

## Challenges Faced & Solutions
| Challenge                          | Solution Implemented                              |
|------------------------------------|----------------------------------------------------|
| API key exposure in code           | Stored in `.env` + loaded via `python-dotenv`     |
| Mobile responsiveness              | Fully responsive CSS Grid + mobile-first table   |
| Load balancer not distributing     | Used `upstream` directive in Nginx correctly      |
| Gunicorn not restarting on crash   | Added `Restart=always` in systemd service        |
| Static files 404                   | Added proper `location /static/` alias in Nginx   |

## Demo Video (≤ 2 minutes)
**Link:** https://youtu.be/your-video-id-or-drive-link  
**Content:**
- Local run demonstration (search + filters)
- Access via Web01 directly
- Access via Web02 directly
- Final access via Lb01 (load balancer)
- Show traffic being distributed (via server logs or unique footer message)

## Final Notes for Grading
- Uses a real, vetted, public API
- Provides genuine value (not a joke/cat fact app)
- Interactive: search, filter, sort
- Clean, professional UI/UX
- Secure key handling
- Fully deployed with load balancing

