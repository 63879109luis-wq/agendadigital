// ============================================================
// models/Task.js — Modelo de tareas escolares
// ============================================================
// Define la estructura de los documentos en la colección
// "tasks" de MongoDB. Cada documento representa una tarea,
// examen, proyecto o recordatorio del estudiante.
// ============================================================

const mongoose = require('mongoose');

// ── Definir el esquema de tarea ────────────────────────────
const TaskSchema = new mongoose.Schema({
    // Referencia al usuario dueño de la tarea.
    // ObjectId es el tipo de ID nativo de MongoDB.
    // ref: 'User' permite hacer .populate() para traer los datos del usuario.
    userId: {
        type:     mongoose.Schema.Types.ObjectId,
        ref:      'User',
        required: true
    },

    // Título de la tarea (ej: "Examen de matemáticas")
    title: {
        type:     String,
        required: true,
        trim:     true   // Elimina espacios al inicio y al final automáticamente
    },

    // Descripción detallada de la tarea (opcional)
    description: {
        type: String,
        trim: true
    },

    // Materia o asignatura (ej: "Matemáticas", "Lengua")
    subject: {
        type: String,
        trim: true
    },

    dueDate:      { type: Date },  // Fecha límite de entrega
    reminderDate: { type: Date },  // Fecha de recordatorio (notificación anticipada)

    // Prioridad de la tarea
    priority: {
        type:    String,
        enum:    ['low', 'medium', 'high'], // Baja, media o alta
        default: 'medium'
    },

    // Estado actual de la tarea
    status: {
        type:    String,
        enum:    ['pending', 'in_progress', 'completed', 'overdue'], // pendiente, en progreso, completada, vencida
        default: 'pending'
    },

    // Tipo de tarea escolar
    type: {
        type:    String,
        enum:    ['homework', 'exam', 'project', 'reminder', 'other'],
        default: 'homework'
    },

    // Archivos adjuntos (imágenes, PDFs, etc.)
    // Es un array de subdocumentos, cada uno con su propia estructura
    attachments: [{
        fileName:   String,
        fileUrl:    String,    // URL pública o cadena Base64 de la imagen
        fileType:   String,    // Tipo de archivo: 'image', 'pdf', etc.
        uploadedAt: { type: Date, default: Date.now } // Fecha de subida automática
    }],

    // Referencia al resultado OCR si la tarea fue creada desde una imagen escaneada.
    // Permite recuperar el texto extraído vinculado a esta tarea.
    ocrResultId: {
        type: mongoose.Schema.Types.ObjectId,
        ref:  'OCRResult'
    },

    tags:         [String],                         // Etiquetas libres (ej: ["urgente", "examen"])
    is_completed: { type: Boolean, default: false }, // Flag rápido de completado
    completed_at: { type: Date },                   // Cuándo se completó la tarea
    created_at:   { type: Date, default: Date.now }, // Fecha de creación
    updated_at:   { type: Date, default: Date.now }, // Fecha de última modificación

    // ── Campos de calificación (rol docente) ────────────────
    grade: {
        type: Number,
        min:  0,
        max:  100
    },                                               // Nota del docente (0–100)
    teacherComment: { type: String, trim: true },    // Comentario/retroalimentación del docente
    gradedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref:  'User'
    },                                               // Referencia al docente que calificó
    gradedAt: { type: Date }                         // Fecha en que se calificó
});

// ── Middleware pre-save ─────────────────────────────────────
// Se ejecuta automáticamente ANTES de guardar cualquier tarea.
// Actualiza el campo updated_at con la fecha actual para mantener
// el registro de cuándo fue modificada por última vez.
TaskSchema.pre('save', function (next) {
    this.updated_at = new Date();
    next(); // Permite que continúe el proceso de guardado
});

// ── Exportar el modelo ──────────────────────────────────────
// Crea la colección "tasks" en MongoDB.
module.exports = mongoose.model('Task', TaskSchema);
