// ============================================================
// routes/actividades.js — CRUD de actividades académicas
// ============================================================
// GET    /api/actividades
// POST   /api/actividades
// PUT    /api/actividades/:id
// DELETE /api/actividades/:id
// GET    /api/actividades/stats
// ============================================================
const express    = require('express');
const router     = express.Router();
const Actividad  = require('../models/Actividad');

// ── GET /api/actividades/stats ───────────────────────────────
router.get('/stats', async (req, res) => {
  try {
    const [total, activas, proximas, finalizadas] = await Promise.all([
      Actividad.countDocuments(),
      Actividad.countDocuments({ estado: 'Activa' }),
      Actividad.countDocuments({ estado: 'Próxima' }),
      Actividad.countDocuments({ estado: 'Finalizada' }),
    ]);
    res.json({ total, activas, proximas, finalizadas });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── GET /api/actividades ─────────────────────────────────────
router.get('/', async (req, res) => {
  try {
    const filter = {};
    if (req.query.tipo)   filter.tipo   = req.query.tipo;
    if (req.query.estado) filter.estado = req.query.estado;
    if (req.query.materiaId) filter.materiaId = req.query.materiaId;
    if (req.query.search) {
      filter.titulo = new RegExp(req.query.search, 'i');
    }
    const actividades = await Actividad.find(filter)
      .populate('materiaId', 'nombre codigo')
      .populate('docenteId', 'name')
      .sort({ fechaEntrega: 1 });
    res.json(actividades);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── POST /api/actividades ────────────────────────────────────
router.post('/', async (req, res) => {
  try {
    const act = await Actividad.create(req.body);
    const populated = await act.populate('materiaId', 'nombre codigo');
    res.status(201).json(populated);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ── PUT /api/actividades/:id ──────────────────────────────────
router.put('/:id', async (req, res) => {
  try {
    const act = await Actividad.findByIdAndUpdate(req.params.id, req.body, { new: true })
      .populate('materiaId', 'nombre codigo')
      .populate('docenteId', 'name');
    if (!act) return res.status(404).json({ error: 'Actividad no encontrada' });
    res.json(act);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ── DELETE /api/actividades/:id ───────────────────────────────
router.delete('/:id', async (req, res) => {
  try {
    await Actividad.findByIdAndDelete(req.params.id);
    res.json({ message: 'Actividad eliminada' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
