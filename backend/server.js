// ============================================================
// server.js — Punto de entrada principal del backend Node.js
// ============================================================
// Este archivo arranca el servidor Express, conecta a MongoDB
// y registra todas las rutas de la API REST.
// ============================================================

// ── Importar dependencias principales ──────────────────────
const express  = require('express');   // Framework web para crear rutas HTTP
const mongoose = require('mongoose');  // ODM para conectar y consultar MongoDB
const cors     = require('cors');      // Permite peticiones desde otros orígenes (Flutter, web, etc.)
const admin    = require('firebase-admin'); // Firebase Admin SDK para enviar notificaciones
require('dotenv').config();            // Carga las variables del archivo .env (MONGODB_URI, PORT, etc.)

// ── Importar path ──────────────────────────────────────────
const path = require('path');

// ── Inicializar Firebase Admin SDK ────────────────────────
const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');

try {
    // Intentar inicializar con service account JSON
    const serviceAccount = require(serviceAccountPath);
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log('🔥 Firebase Admin inicializado con service account');
} catch (err) {
    // Si no existe el archivo, Firebase Admin no enviará notificaciones
    // pero el resto del servidor funciona con normalidad.
    console.warn('⚠️  Firebase Admin: no se encontró firebase-service-account.json');
    console.warn('   Las notificaciones push estarán desactivadas.');
    // Inicializar sin credenciales (modo degradado)
    if (!admin.apps.length) {
        admin.initializeApp();
    }
}

// ── Crear la aplicación Express ────────────────────────────
const app  = express();
const PORT = process.env.PORT || 3001; // Puerto definido en .env o 3001 por defecto

// ── Middlewares globales ────────────────────────────────────
// CORS: permite que la app móvil (Flutter) y otros clientes puedan
//       hacer peticiones HTTP al servidor sin ser bloqueados.
app.use(cors());

// express.json: convierte el cuerpo de las peticiones HTTP a objetos JS.
// limit: '50mb' porque se envían imágenes en Base64 en las peticiones OCR.
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ limit: '50mb', extended: true }));

// Servir archivos subidos (PDFs de tareas) como recursos estáticos.
// Accesibles en: http://servidor:3001/uploads/pdfs/nombre.pdf
const uploadsPath = path.join(__dirname, 'uploads');
app.use('/uploads', express.static(uploadsPath));

// ── Logger global ───────────────────────────────────────────
// Se ejecuta ANTES de cada ruta. Imprime en consola la fecha,
// método HTTP (GET, POST, etc.) y la URL de cada petición recibida.
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    next(); // Pasa el control al siguiente middleware o ruta
});

// ── Cargar modelos de base de datos ─────────────────────────
// Mongoose necesita que los esquemas estén registrados antes de usarlos.
// Aunque no se usen directamente aquí, al hacer require() se registran
// en el mapa global de modelos de Mongoose.
require('./models/User');       // Modelo de usuarios (estudiantes, profesores, admin)
require('./models/Agenda');     // Modelo de eventos de agenda personal
require('./models/Task');       // Modelo de tareas escolares
require('./models/OCRResult');  // Modelo para guardar resultados del escáner OCR
require('./models/History');    // Modelo de historial de acciones del usuario
require('./models/Universe');   // Modelo del universo/galaxia del sistema de gamificación
require('./models/UserToken');  // Modelo de tokens FCM para notificaciones push
require('./models/Materia');       // Modelo de materias académicas
require('./models/Actividad');    // Modelo de actividades académicas
require('./models/Inscripcion');  // Modelo de inscripciones de estudiantes

// ── Conexión a MongoDB ──────────────────────────────────────
// Si existe MONGODB_URI en .env, conecta a MongoDB Atlas (en la nube).
// Si no, conecta a una instancia local de MongoDB.
const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/german_busch_db';

mongoose.connect(MONGO_URI, {
    useNewUrlParser:    true,  // Usa el nuevo parser de URL de MongoDB
    useUnifiedTopology: true   // Usa el nuevo motor de monitoreo de conexiones
})
    .then(() => console.log('✅ MongoDB Conectado →', MONGO_URI.includes('localhost') ? 'LOCAL' : 'ATLAS'))
    .catch(err => console.error('❌ Error al conectar MongoDB:', err.message));

// ── Importar y montar las rutas de la API ──────────────────
// Cada módulo de rutas maneja un conjunto de endpoints REST.
// Se montan bajo prefijos /api/... para organizar la API.
const authRoutes          = require('./routes/auth');          // Registro e inicio de sesión
const agendaRoutes        = require('./routes/agenda');         // CRUD de la agenda personal
const taskRoutes          = require('./routes/tasks');          // CRUD de tareas escolares
const ocrRoutes           = require('./routes/ocr');            // Guardar y consultar resultados OCR
const historyRoutes       = require('./routes/history');        // Historial de actividad del usuario
const universeRoutes      = require('./routes/universe');       // Sistema de universo/gamificación
const notificationRoutes  = require('./routes/notifications'); // Notificaciones push FCM
const adminRoutes         = require('./routes/admin');          // Gestión de usuarios admin
const materiasRoutes        = require('./routes/materias');       // CRUD de materias académicas
const actividadesRoutes     = require('./routes/actividades');    // CRUD de actividades académicas
const inscripcionesRoutes   = require('./routes/inscripciones'); // CRUD de inscripciones de estudiantes

// Montar cada conjunto de rutas bajo su prefijo correspondiente
app.use('/api/auth',          authRoutes);
app.use('/api/agenda',        agendaRoutes);
app.use('/api/tasks',         taskRoutes);
app.use('/api/ocr',           ocrRoutes);
app.use('/api/history',       historyRoutes);
app.use('/api/universe',      universeRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin',         adminRoutes);
app.use('/api/materias',        materiasRoutes);
app.use('/api/actividades',     actividadesRoutes);
app.use('/api/inscripciones',   inscripcionesRoutes);

// ── Ruta raíz ── información general de la API ─────────────
// GET / → devuelve un JSON con el estado del servidor y el mapa
// de todas las rutas disponibles (útil para debugging).
app.get('/', (req, res) => {
    res.json({
        message: 'Colegio Germán Busch "A" Backend en línea ✅',
        version: '2.0.0',
        routes: {
            auth:    '/api/auth    → POST /register, POST /login',
            agenda:  '/api/agenda  → GET /:userId, POST /',
            tasks:   '/api/tasks   → GET /:userId, GET /detail/:id, POST /, PUT /:id, DELETE /:id',
            ocr:     '/api/ocr     → GET /:userId, GET /detail/:id, POST /, POST /failed, DELETE /:id',
            history: '/api/history → GET /:userId, DELETE /:userId',
            universe: '/api/universe → GET /:userId, POST /reset/:userId, POST /planet'
        }
    });
});

// ── Iniciar el servidor ─────────────────────────────────────
// Escucha en todas las interfaces de red (0.0.0.0) para ser
// accesible desde el emulador Android (10.0.2.2) y desde la red local.
app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Servidor corriendo en http://0.0.0.0:${PORT}`);
});

// ── Manejador global de errores ────────────────────────────
// Captura cualquier error lanzado en los middlewares o rutas.
// IMPORTANTE: debe ir al final, después de todas las rutas.
// En modo 'development' incluye el stack trace para facilitar el debug.
app.use((err, req, res, next) => {
    if (err) {
        console.error('🔥 Error Express:', err.message);
        res.status(err.status || 500).json({
            error: err.message,
            stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
        });
    } else {
        next();
    }
});
