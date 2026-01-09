/**
 * TimeFlow Development Server
 * Simple HTTP server for serving the web app
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;
const WEB_DIR = path.join(__dirname, 'web');

const MIME_TYPES = {
    '.html': 'text/html',
    '.css': 'text/css',
    '.js': 'text/javascript',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpeg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
    '.ico': 'image/x-icon',
    '.woff': 'font/woff',
    '.woff2': 'font/woff2',
    '.ttf': 'font/ttf'
};

const server = http.createServer((req, res) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);

    // Parse URL
    let filePath = req.url === '/' ? '/index.html' : req.url;
    filePath = path.join(WEB_DIR, filePath);

    // Security: prevent directory traversal
    if (!filePath.startsWith(WEB_DIR)) {
        res.writeHead(403);
        res.end('Forbidden');
        return;
    }

    // Get file extension
    const ext = path.extname(filePath).toLowerCase();
    const contentType = MIME_TYPES[ext] || 'application/octet-stream';

    // Read and serve file
    fs.readFile(filePath, (err, content) => {
        if (err) {
            if (err.code === 'ENOENT') {
                // File not found - serve index.html for SPA routing
                if (!ext || ext === '.html') {
                    fs.readFile(path.join(WEB_DIR, 'index.html'), (err2, indexContent) => {
                        if (err2) {
                            res.writeHead(500);
                            res.end('Server Error');
                        } else {
                            res.writeHead(200, { 'Content-Type': 'text/html' });
                            res.end(indexContent);
                        }
                    });
                } else {
                    res.writeHead(404);
                    res.end('Not Found');
                }
            } else {
                res.writeHead(500);
                res.end('Server Error');
            }
        } else {
            res.writeHead(200, {
                'Content-Type': contentType,
                'Cache-Control': 'no-cache'
            });
            res.end(content);
        }
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log(`
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║   ████████╗██╗███╗   ███╗███████╗███████╗██╗      ██████╗ ██╗    ║
║   ╚══██╔══╝██║████╗ ████║██╔════╝██╔════╝██║     ██╔═══██╗██║    ║
║      ██║   ██║██╔████╔██║█████╗  █████╗  ██║     ██║   ██║██║    ║
║      ██║   ██║██║╚██╔╝██║██╔══╝  ██╔══╝  ██║     ██║   ██║██║    ║
║      ██║   ██║██║ ╚═╝ ██║███████╗██║     ███████╗╚██████╔╝██║    ║
║      ╚═╝   ╚═╝╚═╝     ╚═╝╚══════╝╚═╝     ╚══════╝ ╚═════╝ ╚═╝    ║
║                                                                  ║
║        Development Server Running                                ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝

Server running at http://localhost:${PORT}

Press Ctrl+C to stop the server.
`);
});

// Handle shutdown gracefully
process.on('SIGINT', () => {
    console.log('\nShutting down server...');
    server.close(() => {
        console.log('Server stopped.');
        process.exit(0);
    });
});
