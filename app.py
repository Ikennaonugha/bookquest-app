from flask import Flask, render_template, request, session
import requests
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
app.secret_key = 'super_secret_key'  # For session

API_BASE = "https://www.googleapis.com/books/v1/volumes"
API_KEY = os.getenv("GOOGLE_BOOKS_API_KEY")

if not API_KEY:
    raise ValueError("No API key set in .env")

@app.route('/', methods=['GET', 'POST'])
def index():
    results = []
    error = None
    if request.method == 'POST':
        query = request.form.get('query')
        lang = request.form.get('language', 'en')
        print_type = request.form.get('print_type', 'all')
        order_by = request.form.get('order_by', 'relevance')
        
        if not query:
            error = "Please enter a search query."
        else:
            params = {
                'q': query,
                'langRestrict': lang,
                'printType': print_type,
                'orderBy': order_by,
                'maxResults': 20,
                'key': API_KEY
            }
            try:
                response = requests.get(API_BASE, params=params)
                response.raise_for_status()
                data = response.json()
                results = data.get('items', [])
                # Cache results in session for quick reload
                session['results'] = results
            except requests.exceptions.RequestException as e:
                error = f"API error: {str(e)}"
    
    return render_template('index.html', results=results, error=error)

if __name__ == '__main__':
    app.run(debug=True)
