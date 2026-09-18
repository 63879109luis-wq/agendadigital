// ============================================================
// models/User.js — Modelo de usuario de MongoDB
// ============================================================
// Define la estructura (esquema) de los documentos en la
// colección "users" de MongoDB. Cada usuario puede ser
// estudiante, profesor o administrador.
// ============================================================

const mongoose = require('mongoose');

// ── Definir el esquema del usuario ─────────────────────────
const UserSchema = new mongoose.Schema({
    name:     { type: String, required: true },  // Nombre completo del usuario (obligatorio)
    email:    { type: String, required: true, unique: true }, // Email único (no se pueden repetir)
    password: { type: String, required: true },  // Contraseña encriptada con bcrypt
    role: {
        type:    String,
        enum:    ['student', 'teacher', 'admin'], // Solo permite estos tres valores
        default: 'student'                        // Por defecto es estudiante
    },
    grade:        { type: String },                // Grado/curso del estudiante, ej: "5A Sec"
    ci:           { type: String },
    telefono:     { type: String },
    tutor:        { type: String },
    tutorTel:     { type: String },
    especialidad: { type: String },
    direccion:    { type: String },
    materias:     { type: String },
    created_at:   { type: Date, default: Date.now } // Fecha de registro (se llena automáticamente)
});

// ── Exportar el modelo ──────────────────────────────────────
// mongoose.model('User', UserSchema) crea la colección "users"
// en MongoDB y permite hacer User.find(), User.create(), etc.
module.exports = mongoose.model('User', UserSchema);
