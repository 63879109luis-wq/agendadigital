// ============================================================
// models/History.js — Modelo de historial de actividades
// ============================================================
// Registra cada acción importante que realiza un usuario
// (login, crear tarea, escanear imagen, etc.). Funciona como
// un log de auditoría: qué hizo, cuándo y sobre qué recurso.
// ============================================================

const mongoose = require('mongoose');

// ── Definir el esquema de historial ────────────────────────
const HistorySchema = new mongoose.Schema({
    // Usuario que realizó la acción
    userId: {
        type:     mongoose.Schema.Types.ObjectId,
        ref:      'User',
        required: true
    },

    // Tipo de acción realizada (campo controlado por enum)
    action: {
        type:     String,
        required: true,
        enum: [
            // ── Autenticación ────────────────────────────
            'user_register',   // El usuario se registró por primera vez
            'user_login',      // El usuario inició sesión
            'user_logout',     // El usuario cerró sesión
            'password_change', // El usuario cambió su contraseña

            // ── Tareas ───────────────────────────────────
            'task_create',     // Se creó una nueva tarea
            'task_update',     // Se modificó una tarea existente
            'task_complete',   // Se marcó una tarea como completada
            'task_delete',     // Se eliminó una tarea

            // ── OCR / Escaneo de imágenes ─────────────────
            'ocr_upload',      // El usuario subió una imagen para escanear
            'ocr_process',     // El OCR comenzó a procesar la imagen
            'ocr_complete',    // El OCR terminó exitosamente
            'ocr_failed',      // El OCR falló al procesar la imagen

            // ── Agenda ───────────────────────────────────
            'agenda_create',   // Se creó un evento en la agenda
            'agenda_update',   // Se modificó un evento de la agenda
            'agenda_delete',   // Se eliminó un evento de la agenda

            // ── General ──────────────────────────────────
            'other'            // Cualquier otra acción no categorizada
        ]
    },

    // Tipo de recurso sobre el que se realizó la acción
    resourceType: {
        type:    String,
        enum:    ['User', 'Task', 'OCRResult', 'Agenda', 'System'],
        default: 'System'
    },

    // ID del documento afectado (la tarea creada, el OCR procesado, etc.)
    resourceId: {
        type: mongoose.Schema.Types.ObjectId
    },

    // Descripción legible para mostrar en la UI (ej: 'Tarea creada: "Examen de Historia"')
    description: {
        type: String
    },

    // Datos adicionales opcionales: payload anterior, detalles extra, etc.
    // Mixed permite guardar cualquier estructura JSON arbitraria.
    metadata: {
        type: mongoose.Schema.Types.Mixed
    },

    ipAddress: { type: String },  // IP del cliente que realizó la petición (para auditoría)
    userAgent: { type: String },  // Navegador/dispositivo del cliente
    timestamp: { type: Date, default: Date.now } // Fecha y hora exacta de la acción
});

// ── Índices para búsquedas rápidas ─────────────────────────
// Sin índices, MongoDB haría un "full scan" de toda la colección.
// Estos índices aceleran las consultas más comunes del historial:

// Índice compuesto: buscar historial de un usuario ordenado por fecha (más reciente primero)
HistorySchema.index({ userId: 1, timestamp: -1 });

// Índice simple: filtrar por tipo de acción (ej: solo 'ocr_complete')
HistorySchema.index({ action: 1 });

// Índice compuesto: buscar el historial de un recurso específico
// (ej: todos los cambios a una Tarea con ID X)
HistorySchema.index({ resourceType: 1, resourceId: 1 });

// ── Exportar el modelo ──────────────────────────────────────
// Crea la colección "histories" en MongoDB.
module.exports = mongoose.model('History', HistorySchema);
