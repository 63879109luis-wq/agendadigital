// ============================================================
// models/Inscripcion.js — Modelo de inscripción de estudiantes
// ============================================================
// Cada documento representa la inscripción de un estudiante
// a una materia específica. La crea/aprueba el administrador
// desde el panel web-admin.
// ============================================================
const mongoose = require('mongoose');

const InscripcionSchema = new mongoose.Schema({
  // ── Datos del estudiante ──────────────────────────────────
  estudianteId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null }, // Si el estudiante ya tiene cuenta
  nombre:       { type: String, required: true },  // Nombre completo
  ci:           { type: String, required: true },  // Cédula de identidad
  curso:        { type: String, required: true },  // Ej: "1° de Secundaria"
  nivel:        { type: String, default: 'Secundaria' },
  gestion:      { type: String, default: 'Gestión 2025' },
  tutor:        { type: String, default: '' },
  tutorTel:     { type: String, default: '' },

  // ── Materia a la que se inscribe ──────────────────────────
  asignatura:   { type: String, default: '' },     // Nombre de la materia
  materiaId:    { type: mongoose.Schema.Types.ObjectId, ref: 'Materia', default: null }, // Referencia al modelo Materia

  // ── Gestión de la inscripción ─────────────────────────────
  estado:       { type: String, enum: ['Pendiente', 'Aprobada', 'Rechazada'], default: 'Pendiente' },
  revisadoPor:  { type: String, default: '' },
  obs:          { type: String, default: '' },
  fecha:        { type: String, default: '' },
  hora:         { type: String, default: '' },
  created_at:   { type: Date, default: Date.now },
});

module.exports = mongoose.model('Inscripcion', InscripcionSchema);
