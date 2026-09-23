// ============================================================
// config.js — Configuración de conexión al backend
// ============================================================
// ⚠️  INSTRUCCIONES:
//
//  LOCAL (tu PC):
//    Deja BACKEND_URL = 'auto' para detectar automáticamente.
//
//  EN EL SERVIDOR:
//    Cambia BACKEND_URL por la IP o dominio de tu servidor.
//    Ejemplos:
//      window.BACKEND_URL = 'http://192.168.1.100:3001';
//      window.BACKEND_URL = 'http://midominio.com:3001';
//      window.BACKEND_URL = 'https://mi-backend.onrender.com';
//
// ============================================================

(function () {
    // ── CONFIGURA AQUÍ LA URL DE TU BACKEND ──────────────────
    var BACKEND_URL = 'auto';   // 'auto' detecta si estás en local o en el servidor
    // ─────────────────────────────────────────────────────────

    if (BACKEND_URL === 'auto') {
        // Detección automática:
        // Si el panel corre en localhost → backend en localhost:3001
        // Si el panel corre en otro host → backend en mismo host, puerto 3001
        var host = window.location.hostname;
        if (host === 'localhost' || host === '127.0.0.1') {
            window.BACKEND_URL = 'http://localhost:3001';
        } else {
            // Mismo servidor donde está el panel, puerto 3001
            window.BACKEND_URL = window.location.protocol + '//' + host + ':3001';
        }
    } else {
        window.BACKEND_URL = BACKEND_URL;
    }

    console.log('🔧 Backend URL configurada:', window.BACKEND_URL);
})();
