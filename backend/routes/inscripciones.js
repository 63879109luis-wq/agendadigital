// ============================================================
// routes/inscripciones.js — CRUD de inscripciones académicas
// ============================================================
// GET    /api/inscripciones            → listar con filtros
// GET    /api/inscripciones/materia/:nombre → estudiantes de una materia
// GET    /api/inscripciones/docente/:docenteId → todos los estudiantes de las materias del docente
// POST   /api/inscripciones            → crear inscripción
// PUT    /api/inscripciones/:id        → actualizar (aprobar/rechazar/editar)
// DELETE /api/inscripciones/:id        → eliminar
// ============================================================
const express      = require('express');
const router       = express.Router();
const Inscripcion  = require('../models/Inscripcion');
const Materia      = require('../models/Materia');
const User         = require('../models/User');

// ── GET /api/inscripciones ────────────────────────────────────
// Filtros opcionales: estado, ci, nivel, asignatura
router.get('/', async (req, res) => {
  try {
    const filter = {};
    if (req.query.estado)     filter.estado     = req.query.estado;
    if (req.query.ci)         filter.ci         = req.query.ci;
    if (req.query.nivel)      filter.nivel      = req.query.nivel;
    if (req.query.asignatura) filter.asignatura = new RegExp(req.query.asignatura, 'i');
    if (req.query.curso)      filter.curso      = new RegExp(req.query.curso, 'i');
    if (req.query.search) {
      const re = new RegExp(req.query.search, 'i');
      filter.$or = [{ nombre: re }, { ci: re }, { curso: re }];
    }

    const inscripciones = await Inscripcion.find(filter)
      .populate('estudianteId', 'name email grade')
      .populate('materiaId', 'nombre codigo area')
      .sort({ created_at: -1 });

    res.json(inscripciones);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── GET /api/inscripciones/docente/:docenteId ─────────────────
// Devuelve todos los estudiantes inscritos en las materias del docente.
// Primero obtiene las materias asignadas al docente, luego busca
// inscripciones aprobadas en esas materias.
router.get('/docente/:docenteId', async (req, res) => {
  try {
    const { docenteId } = req.params;

    // Validar que el docenteId sea un ObjectId válido
    const mongoose = require('mongoose');
    if (!mongoose.Types.ObjectId.isValid(docenteId)) {
      return res.json({ materias: [], porMateria: {}, estudiantes: [], total: 0 });
    }

    // 1. Obtener materias asignadas al docente desde el modelo Materia
    let materias = await Materia.find({ docenteId, activa: true });
    if (!materias.length) {
      materias = await Materia.find({ docenteId });
    }

    let nombresMaterias = materias.map(m => m.nombre);

    // 2. FALLBACK: Si no hay materias en el modelo Materia,
    //    usar el campo User.materias del docente
    if (!nombresMaterias.length) {
      const docente = await User.findById(docenteId).select('materias grade especialidad');
      if (docente) {
        // User.materias puede ser string CSV ("Matematicas,Historia") o undefined
        const materiasStr = docente.materias || docente.grade || docente.especialidad || '';
        if (materiasStr && materiasStr.trim()) {
          nombresMaterias = materiasStr.split(',').map(s => s.trim()).filter(s => s.length > 0);
        }
      }
    }

    if (!nombresMaterias.length) {
      return res.json({ materias: [], porMateria: {}, estudiantes: [], total: 0 });
    }

    // 3. Buscar inscripciones aprobadas en esas materias (case-insensitive)
    const filtroAsignatura = nombresMaterias.map(n => new RegExp(`^${n.trim()}$`, 'i'));

    let inscripciones = await Inscripcion.find({
      estado: 'Aprobada',
      asignatura: { $in: filtroAsignatura }
    })
      .populate('estudianteId', 'name email grade ci')
      .sort({ nombre: 1 });

    // Fallback: si no hay inscripciones aprobadas, mostrar todas
    if (!inscripciones.length) {
      inscripciones = await Inscripcion.find({
        asignatura: { $in: filtroAsignatura }
      })
        .populate('estudianteId', 'name email grade ci')
        .sort({ nombre: 1 });
    }

    // 4. Agrupar por materia — serializar como objetos planos
    const porMateria = {};
    nombresMaterias.forEach(m => { porMateria[m] = []; });

    inscripciones.forEach(insc => {
      const matchKey = nombresMaterias.find(n =>
        n.trim().toLowerCase() === (insc.asignatura || '').trim().toLowerCase()
      );
      if (matchKey) {
        porMateria[matchKey].push({
          _id:        insc._id,
          nombre:     insc.nombre,
          ci:         insc.ci,
          curso:      insc.curso,
          nivel:      insc.nivel,
          gestion:    insc.gestion,
          tutor:      insc.tutor,
          tutorTel:   insc.tutorTel,
          asignatura: insc.asignatura,
          estado:     insc.estado,
          estudianteId: insc.estudianteId,
        });
      }
    });

    // Serializar lista de estudiantes
    const estudiantesPlanos = inscripciones.map(insc => ({
      _id:        insc._id,
      nombre:     insc.nombre,
      ci:         insc.ci,
      curso:      insc.curso,
      nivel:      insc.nivel,
      gestion:    insc.gestion,
      tutor:      insc.tutor,
      tutorTel:   insc.tutorTel,
      asignatura: insc.asignatura,
      estado:     insc.estado,
      estudianteId: insc.estudianteId,
    }));

    // Construir respuesta de materias (usar modelo Materia si existe, sino datos sintéticos)
    const materiasResp = materias.length > 0
      ? materias.map(m => ({
          _id: m._id,
          nombre: m.nombre,
          codigo: m.codigo,
          area: m.area,
          semestre: m.semestre,
          totalEstudiantes: (porMateria[m.nombre] || []).length,
        }))
      : nombresMaterias.map(nombre => ({
          _id: null,
          nombre,
          codigo: '',
          area: '',
          semestre: '',
          totalEstudiantes: (porMateria[nombre] || []).length,
        }));

    res.json({
      materias: materiasResp,
      porMateria,
      estudiantes: estudiantesPlanos,
      total: inscripciones.length,
    });
  } catch (e) {
    console.error('Error en /inscripciones/docente:', e);
    res.status(500).json({ error: e.message });
  }
});

// ── GET /api/inscripciones/materia/:nombre ─────────────────────
router.get('/materia/:nombre', async (req, res) => {
  try {
    const re = new RegExp(`^${req.params.nombre.trim()}$`, 'i');
    const inscripciones = await Inscripcion.find({ asignatura: re, estado: 'Aprobada' })
      .populate('estudianteId', 'name email grade')
      .sort({ nombre: 1 });
    res.json(inscripciones);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ── POST /api/inscripciones ──────────────────────────────────
router.post('/', async (req, res) => {
  try {
    // Si viene un CI, intentar vincular con estudiante existente en Users
    if (req.body.ci) {
      const user = await User.findOne({ ci: req.body.ci, role: 'student' });
      if (user) req.body.estudianteId = user._id;
    }
    // Si viene nombre de materia, intentar vincular con Materia
    if (req.body.asignatura) {
      const materia = await Materia.findOne({ nombre: new RegExp(`^${req.body.asignatura.trim()}$`, 'i') });
      if (materia) req.body.materiaId = materia._id;
    }

    const insc = await Inscripcion.create(req.body);
    res.status(201).json(insc);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ── PUT /api/inscripciones/:id ────────────────────────────────
router.put('/:id', async (req, res) => {
  try {
    // Si se aprueba la inscripción, intentar vincular estudianteId
    if (req.body.estado === 'Aprobada') {
      const current = await Inscripcion.findById(req.params.id);
      if (current && !current.estudianteId) {
        const user = await User.findOne({ ci: current.ci, role: 'student' });
        if (user) req.body.estudianteId = user._id;
      }
      // También intentar vincular materiaId si tiene asignatura
      if (current && current.asignatura && !current.materiaId) {
        const materia = await Materia.findOne({ nombre: new RegExp(`^${current.asignatura.trim()}$`, 'i') });
        if (materia) req.body.materiaId = materia._id;
      }
    }

    const insc = await Inscripcion.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!insc) return res.status(404).json({ error: 'Inscripción no encontrada' });
    res.json(insc);
  } catch (e) {
    res.status(400).json({ error: e.message });
  }
});

// ── DELETE /api/inscripciones/:id ────────────────────────────
router.delete('/:id', async (req, res) => {
  try {
    await Inscripcion.findByIdAndDelete(req.params.id);
    res.json({ message: 'Inscripción eliminada' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

module.exports = router;
