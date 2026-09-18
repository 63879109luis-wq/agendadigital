// ============================================================
// routes/materias.js — CRUD de materias académicas
// ============================================================
// GET    /api/materias
// POST   /api/materias
// PUT    /api/materias/:id
// DELETE /api/materias/:id
// ============================================================
const express  = require('express');
const router   = express.Router();
const Materia  = require('../models/Materia');
const User     = require('../models/User');

// ── GET /api/materias ────────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const filter = {};
    if (req.query.activa !== undefined) filter.activa = req.query.activa === 'true';
    if (req.query.docenteId) filter.docenteId = req.query.docenteId; // ← Filtrar por docente asignado
    if (req.query.search) {
      const re = new RegExp(req.query.search, 'i');
      filter.$or = [{ nombre: re }, { codigo: re }, { area: re }];
    }
    const materias = await Materia.find(filter)
      .populate('docenteId', 'name email')
      .sort({ created_at: -1 });
    res.json(materias);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── POST /api/materias ───────────────────────────────────────
router.post('/', async (req, res) => {
  try {
    const materia = await Materia.create(req.body);
    const populated = await materia.populate('docenteId', 'name email');
    res.status(201).json(populated);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ── PUT /api/materias/:id ─────────────────────────────────────
router.put('/:id', async (req, res) => {
  try {
    const materia = await Materia.findByIdAndUpdate(req.params.id, req.body, { new: true })
      .populate('docenteId', 'name email');
    if (!materia) return res.status(404).json({ error: 'Materia no encontrada' });
    res.json(materia);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ── DELETE /api/materias/:id ──────────────────────────────────
router.delete('/:id', async (req, res) => {
  try {
    await Materia.findByIdAndDelete(req.params.id);
    res.json({ message: 'Materia eliminada' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
