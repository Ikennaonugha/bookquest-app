// Book Finder Application - Main Logic
// This file contains all the application functionality

let currentQuery = '';
let booksData = [];

/**
 * Handle Enter key press in search input
 */
function handleKeyPress(event) {
    if (event.key === 'Enter') {
        searchBooks();
    }
}

/**
 * Toggle the visibility of filter options
 */
function toggleFilters() {
    const filters = document.getElementById('filters');
    filters.classList.toggle('hidden');
}

/**
 * Apply current filters and re-search
 */
function applyFilters() {
    if (currentQuery) {
        searchBooks();
    }
}

/**
 * Main function to search books using Google Books API
 */
async function searchBooks() {
    const searchInput = document.getElementById('searchInput');
    const query = searchInput.value.trim();

    // Validate search input
    if (!query) {
        showError('Please enter a search term');
        return;
    }

    // Check if API key is configured
    if (!CONFIG.API_KEY || CONFIG.API_KEY === 'YOUR_API_KEY_HERE') {
        showError('API key not configured. Please add your Google Books API key to config.js');
        return;
    }

    currentQuery = query;
    const sortBy = document.getElementById('sortBy').value;
    const category = document.getElementById('category').value;

    // Update UI to show loading state
    document.getElementById('searchBtn').disabled = true;
    document.getElementById('searchBtn').textContent = 'Searching...';
    document.getElementById('loading').style.display = 'block';
    document.getElementById('booksGrid').innerHTML = '';
    document.getElementById('resultsInfo').style.display = 'none';
    hideError();

    try {
        // Build API URL with parameters
        const orderBy = sortBy === 'newest' ? '&orderBy=newest' : '&orderBy=relevance';
        const categoryFilter = category !== 'all' ? `+subject:${category}` : '';
        
        const url = `${CONFIG.API_BASE_URL}?q=${encodeURIComponent(query)}${categoryFilter}${orderBy}&maxResults=40&key=${CONFIG.API_KEY}`;
        
        const response = await fetch(url);

        if (!response.ok) {
            if (response.status === 403) {
                throw new Error('API key is invalid or has exceeded quota. Please check your API key.');
            } else if (response.status === 400) {
                throw new Error('Invalid search query. Please try different search terms.');
            } else {
                throw new Error(`API error: ${response.status}. Please try again later.`);
            }
        }

        const data = await response.json();

        if (data.items && data.items.length > 0) {
            booksData = data.items;
            displayBooks(booksData);
            document.getElementById('resultsInfo').textContent = `Found ${booksData.length} results`;
            document.getElementById('resultsInfo').style.display = 'block';
        } else {
            showError('No books found. Try a different search term or adjust your filters.');
        }
    } catch (error) {
        console.error('Search error:', error);
        showError(error.message || 'An error occurred while searching. Please check your connection and try again.');
    } finally {
        // Reset UI state
        document.getElementById('searchBtn').disabled = false;
        document.getElementById('searchBtn').textContent = 'Search';
        document.getElementById('loading').style.display = 'none';
    }
}

/**
 * Display books in grid layout
 * @param {Array} books - Array of book objects from API
 */
function displayBooks(books) {
    const grid = document.getElementById('booksGrid');
    grid.innerHTML = '';

    books.forEach(book => {
        const info = book.volumeInfo;
        const card = document.createElement('div');
        card.className = 'book-card';

        // Get book cover image with higher quality or use placeholder
        const coverImage = info.imageLinks?.thumbnail || info.imageLinks?.smallThumbnail;
        // Remove zoom parameter and use higher quality image
        const highQualityImage = coverImage ? coverImage.replace('http:', 'https:').replace('&zoom=1', '') : null;
        const coverHTML = highQualityImage 
            ? `<img src="${highQualityImage}" alt="${escapeHtml(info.title)}" loading="lazy">`
            : '<div class="book-cover-placeholder">📖</div>';

        // Format book information
        const authors = info.authors ? `by ${escapeHtml(info.authors.join(', '))}` : 'Author unknown';
        const publishedDate = info.publishedDate ? `Published: ${escapeHtml(info.publishedDate)}` : '';
        const category = info.categories ? `<span class="book-category">${escapeHtml(info.categories[0])}</span>` : '';
        const description = info.description ? `<div class="book-description">${escapeHtml(info.description)}</div>` : '';
        const previewLink = info.previewLink ? `<a href="${info.previewLink}" target="_blank" rel="noopener noreferrer" class="book-link">View on Google Books →</a>` : '';

        card.innerHTML = `
            <div class="book-cover">
                ${coverHTML}
            </div>
            <div class="book-info">
                <div class="book-title">${escapeHtml(info.title)}</div>
                <div class="book-authors">${authors}</div>
                ${publishedDate ? `<div class="book-date">${publishedDate}</div>` : ''}
                ${category}
                ${description}
                ${previewLink}
            </div>
        `;

        grid.appendChild(card);
    });
}

/**
 * Show error message to user
 * @param {string} message - Error message to display
 */
function showError(message) {
    const errorDiv = document.getElementById('errorMessage');
    errorDiv.innerHTML = `<div class="error-message">⚠️ ${escapeHtml(message)}</div>`;
}

/**
 * Hide error message
 */
function hideError() {
    document.getElementById('errorMessage').innerHTML = '';
}

/**
 * Escape HTML to prevent XSS attacks
 * @param {string} text - Text to escape
 * @returns {string} Escaped text
 */
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// Initialize application
document.addEventListener('DOMContentLoaded', function() {
    console.log('Book Finder Application initialized');
    
    // Check if API key is configured
    if (!CONFIG.API_KEY || CONFIG.API_KEY === 'YOUR_API_KEY_HERE') {
        showError('API key not configured. Please add your Google Books API key to config.js');
    }
});