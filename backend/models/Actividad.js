// ============================================================
// models/Actividad.js — Modelo de actividad académica
// ============================================================
const mongoose = require('mongoose');

const ActividadSchema = new mongoose.Schema({
  titulo:      { type: String, required: true },
  descripcion: { type: String, default: '' },
  tipo:        { type: String, enum: ['Tarea', 'Examen', 'Cuestionario', 'Proyecto', 'Reunión', 'Otro'], default: 'Tarea' },
  materiaId:   { type: mongoose.Schema.Types.ObjectId, ref: 'Materia', default: null },
  docenteId:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  fechaEntrega:{ type: Date, required: true },
  estado:      { type: String, enum: ['Activa', 'Próxima', 'Finalizada', 'Cancelada'], default: 'Próxima' },
  puntaje:     { type: Number, default: 100 },
  created_at:  { type: Date, default: Date.now },
});

module.exports = mongoose.model('Actividad', ActividadSchema);
