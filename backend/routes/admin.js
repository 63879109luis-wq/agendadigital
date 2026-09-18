// ============================================================
// routes/admin.js — Gestión de usuarios por rol (admin panel)
// ============================================================
// GET    /api/admin/users?role=admin|teacher|student
// POST   /api/admin/users
// PUT    /api/admin/users/:id
// DELETE /api/admin/users/:id
// GET    /api/admin/stats
// ============================================================
const express   = require('express');
const router    = express.Router();
const bcrypt    = require('bcryptjs');
const mongoose  = require('mongoose');
const User      = require('../models/User');

// Helper: verificar si un string es un ObjectId válido de MongoDB
function esObjectIdValido(id) {
  return mongoose.Types.ObjectId.isValid(id) && String(new mongoose.Types.ObjectId(id)) === id;
}

// ── GET /api/admin/stats ─────────────────────────────────────
router.get('/stats', async (req, res) => {
  try {
    const [admins, teachers, students] = await Promise.all([
      User.countDocuments({ role: 'admin' }),
      User.countDocuments({ role: 'teacher' }),
      User.countDocuments({ role: 'student' }),
    ]);
    res.json({ admins, teachers, students, total: admins + teachers + students });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── GET /api/admin/users ─────────────────────────────────────
router.get('/users', async (req, res) => {
  try {
    const filter = {};
    if (req.query.role) filter.role = req.query.role;
    if (req.query.search) {
      const re = new RegExp(req.query.search, 'i');
      filter.$or = [{ name: re }, { email: re }];
    }
    const users = await User.find(filter).select('-password').sort({ created_at: -1 });
    res.json(users);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── POST /api/admin/users ────────────────────────────────────
router.post('/users', async (req, res) => {
  try {
    const { name, email, password, role, grade, ci, telefono, tutor, tutorTel, especialidad, direccion, materias } = req.body;
    const existing = await User.findOne({ email });
    if (existing) return res.status(400).json({ error: 'El correo ya está registrado en la base de datos' });

    const hashed = await bcrypt.hash(password || '123456', 10);
    const user = await User.create({
      name,
      email,
      password: hashed,
      role: role || 'student',
      grade,
      ci,
      telefono,
      tutor,
      tutorTel,
      especialidad,
      direccion,
      materias
    });
    const obj = user.toObject();
    delete obj.password;
    res.status(201).json(obj);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ── PUT /api/admin/users/:id ─────────────────────────────────
router.put('/users/:id', async (req, res) => {
  // Validar que el ID sea un ObjectId de MongoDB antes de consultar
  if (!esObjectIdValido(req.params.id)) {
    return res.status(400).json({ error: 'ID de usuario inválido' });
  }
  try {
    const updates = { ...req.body };
    if (updates.password && updates.password.trim() !== '') {
      updates.password = await bcrypt.hash(updates.password, 10);
    } else {
      delete updates.password;
    }
    const user = await User.findByIdAndUpdate(req.params.id, updates, { new: true }).select('-password');
    if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });
    res.json(user);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ── DELETE /api/admin/users/:id ──────────────────────────────
router.delete('/users/:id', async (req, res) => {
  // Validar que el ID sea un ObjectId de MongoDB antes de consultar
  if (!esObjectIdValido(req.params.id)) {
    return res.status(400).json({ error: 'ID de usuario inválido' });
  }
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ message: 'Usuario eliminado' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
