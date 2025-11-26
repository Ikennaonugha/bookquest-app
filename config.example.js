// Configuration Template for Book Finder Application
// Copy this file to config.js and add your actual API key
// DO NOT commit config.js to version control

const CONFIG = {
    // Google Books API Configuration
    // Get your API key from: https://console.cloud.google.com/apis/credentials
    API_KEY: 'YOUR_API_KEY_HERE', // Replace with your actual Google Books API key
    API_BASE_URL: 'https://www.googleapis.com/books/v1/volumes',
    
    // Application Settings
    MAX_RESULTS: 40,
    DEFAULT_SORT: 'relevance',
    
    // API Rate Limits (for reference)
    // Free tier: 1,000 requests per day
    // Per user: 100 requests per 100 seconds
};

// Validate configuration on load
(function validateConfig() {
    if (CONFIG.API_KEY === 'YOUR_API_KEY_HERE') {
        console.warn('⚠️ API key not configured. Please add your Google Books API key.');
        console.info('📖 Get your API key from: https://console.cloud.google.com/apis/credentials');
    }
})();