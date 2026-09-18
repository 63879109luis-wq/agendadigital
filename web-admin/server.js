// ============================================================
// server.js — Servidor estático para el Panel Administrativo
// Sirve index.html, style.css y app.js en el puerto 8090
// Uso: node server.js
// ============================================================

const http = require('http');
const fs   = require('fs');
const path = require('path');

const PORT = 8090;
const DIR  = __dirname;

const MIME = {
    '.html': 'text/html; charset=utf-8',
    '.css':  'text/css; charset=utf-8',
    '.js':   'application/javascript; charset=utf-8',
    '.json': 'application/json',
    '.png':  'image/png',
    '.jpg':  'image/jpeg',
    '.svg':  'image/svg+xml',
    '.ico':  'image/x-icon',
    '.woff': 'font/woff',
    '.woff2':'font/woff2',
};

const server = http.createServer((req, res) => {
    // Ruta solicitada
    let urlPath = req.url.split('?')[0];
    if (urlPath === '/') urlPath = '/login.html';

    const filePath = path.join(DIR, urlPath);
    const ext      = path.extname(filePath);
    const mimeType = MIME[ext] || 'application/octet-stream';

    fs.readFile(filePath, (err, data) => {
        if (err) {
            // Si no encuentra el archivo, redirige al login (SPA fallback)
            fs.readFile(path.join(DIR, 'login.html'), (err2, html) => {
                if (err2) {
                    res.writeHead(404); res.end('404 Not Found');
                } else {
                    res.writeHead(200, {
                        'Content-Type': 'text/html; charset=utf-8',
                        'Access-Control-Allow-Origin': '*',
                        'Cache-Control': 'no-cache',
                    });
                    res.end(html);
                }
            });
            return;
        }

        res.writeHead(200, {
            'Content-Type': mimeType,
            'Access-Control-Allow-Origin': '*',
            'Cache-Control': 'no-cache',
        });
        res.end(data);
    });
});

server.listen(PORT, '0.0.0.0', () => {
    console.log('');
    console.log('╔══════════════════════════════════════════╗');
    console.log('║   PANEL ADMINISTRATIVO — Colegio G.B.   ║');
    console.log('╠══════════════════════════════════════════╣');
    console.log(`║   ✅ Servidor corriendo en:              ║`);
    console.log(`║      http://localhost:${PORT}              ║`);
    console.log('║                                          ║');
    console.log('║   Ctrl+C para detener el servidor        ║');
    console.log('╚══════════════════════════════════════════╝');
    console.log('');
});

server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.error(`❌ El puerto ${PORT} ya está en uso.`);
        console.error(`   Cierra el otro proceso y vuelve a ejecutar.`);
    } else {
        console.error('❌ Error del servidor:', err.message);
    }
    process.exit(1);
});
