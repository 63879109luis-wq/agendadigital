// ============================================================
// models/Agenda.js — Modelo de eventos de agenda personal
// ============================================================
// Define la estructura de los documentos en la colección
// "agendas" de MongoDB. Cada ítem representa un evento
// personal del estudiante (tarea, examen o recordatorio).
// ============================================================

const mongoose = require('mongoose');

// ── Definir el esquema de agenda ───────────────────────────
const AgendaSchema = new mongoose.Schema({
    userId: { type: String, required: true },   // ID del usuario dueño de este evento
    title:  { type: String, required: true },   // Título del evento (obligatorio)
    description: { type: String },              // Descripción opcional del evento
    date: { type: Date, required: true },       // Fecha del evento (obligatorio)
    subject: { type: String },                  // Materia asociada (ej: "Historia", "Matemáticas")
    type: {
        type:    String,
        enum:    ['homework', 'exam', 'reminder'], // Solo puede ser tarea, examen o recordatorio
        default: 'homework'                        // Por defecto es tarea
    },
    imageUrl:     { type: String },             // URL o Base64 de imagen adjunta (opcional)
    is_completed: { type: Boolean, default: false }, // Si el evento ya fue completado
    created_at:   { type: Date, default: Date.now },  // Fecha de creación automática
    // ── Entrega de PDF (estudiante) ──────────────────────────
    pdfSubmission: {
        fileName:    { type: String },           // Nombre del archivo PDF entregado
        filePath:    { type: String },           // Ruta en disco del PDF (nuevo sistema)
        fileSize:    { type: Number },           // Tamaño en bytes del PDF
        fileBase64:  { type: String },           // Base64 del PDF (legado, ya no se usa)
        note:        { type: String },           // Nota del estudiante
        submittedAt: { type: Date }              // Fecha/hora de entrega
    },
    // ── Calificación del docente ──────────────────────────────
    grading: {
        grade:          { type: Number },        // Nota asignada por el docente (0-100)
        teacherComment: { type: String },        // Comentario/retroalimentación del docente
        teacherId:      { type: String },        // ID del docente que calificó
        gradedAt:       { type: Date }           // Fecha/hora de calificación
    },
    graded: { type: Boolean, default: false },   // Si ya fue calificada
});

// ── Exportar el modelo ──────────────────────────────────────
// Crea la colección "agendas" en MongoDB.
module.exports = mongoose.model('Agenda', AgendaSchema);
