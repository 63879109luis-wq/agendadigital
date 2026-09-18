// ============================================================
// models/Materia.js — Modelo de materia académica
// ============================================================
const mongoose = require('mongoose');

const MateriaSchema = new mongoose.Schema({
  nombre:      { type: String, required: true },
  codigo:      { type: String, required: true, unique: true },
  descripcion: { type: String, default: '' },
  area:        { type: String, default: 'General' },
  semestre:    { type: String, default: '' },
  docenteId:   { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
  activa:      { type: Boolean, default: true },
  created_at:  { type: Date, default: Date.now },
});

module.exports = mongoose.model('Materia', MateriaSchema);
