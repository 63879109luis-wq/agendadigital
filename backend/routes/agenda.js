// ============================================================
// routes/agenda.js — Rutas de agenda personal
// ============================================================
// Gestiona los eventos de la agenda de cada usuario:
//   GET  /api/agenda/:userId         → Listar todos los eventos
//   POST /api/agenda/                → Crear un nuevo evento
//   POST /api/agenda/:id/submit-pdf  → Entregar PDF de tarea (estudiante)
// ============================================================

const express = require('express');
const router  = express.Router();
const Agenda  = require('../models/Agenda');
const User    = require('../models/User');
const multer  = require('multer'); // Para recibir archivos PDF
const path    = require('path');
const fs      = require('fs');

// ── Carpeta de PDFs ─────────────────────────────────────────
// Los PDFs se guardan en disco en lugar de Base64 en MongoDB
// para evitar el límite de 16 MB por documento de MongoDB BSON.
const PDF_DIR = path.join(__dirname, '..', 'uploads', 'pdfs');
if (!fs.existsSync(PDF_DIR)) fs.mkdirSync(PDF_DIR, { recursive: true });

// Multer: guarda el PDF directamente en disco, máx 50 MB
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, PDF_DIR),
    filename:    (req, file, cb) => {
        // Nombre único: agendaId_timestamp.pdf
        const safeName = file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_');
        cb(null, `${req.params.id}_${Date.now()}_${safeName}`);
    }
});
const upload = multer({
    storage,
    limits:  { fileSize: 50 * 1024 * 1024 }, // 50 MB
    fileFilter: (req, file, cb) => {
        file.mimetype === 'application/pdf'
            ? cb(null, true)
            : cb(new Error('Solo se permiten archivos PDF'), false);
    }
});

// Helper para crear expresión regular insensible a acentos y mayúsculas
function makeAccentInsensitiveRegex(str) {
    if (!str) return null;
    const clean = str.trim();
    if (!clean) return null;
    const escaped = clean.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const pattern = escaped
        .replace(/[aáÁA]/g, '[aáÁA]')
        .replace(/[eéÉE]/g, '[eéÉE]')
        .replace(/[iíÍI]/g, '[iíÍI]')
        .replace(/[oóÓO]/g, '[oóÓO]')
        .replace(/[uúÚüÜU]/g, '[uúÚüÜU]')
        .replace(/[nñÑN]/g, '[nñÑN]');
    return new RegExp(pattern, 'i');
}

// ── GET /api/agenda/submitted ─────────────────────────────
// (ROL DOCENTE) Devuelve todos los items de agenda con PDF entregado
// que están pendientes de calificación (graded: false).
// IMPORTANTE: esta ruta debe ir ANTES de /:userId para que Express
// no interprete "submitted" como un userId.
// Admite filtros opcionales:
//   ?subject=Historia    → Filtrar por materia
//   ?teacherId=xxx       → Filtrar por materias asignadas al docente
router.get('/submitted', async (req, res) => {
    try {
        const { subject, teacherId } = req.query;

        // Filtrar items con PDF entregado y sin calificar.
        // Usamos $or para capturar: graded=false, graded=null, o campo ausente.
        const filter = {
            'pdfSubmission.submittedAt': { $exists: true },
            $or: [
                { graded: false },
                { graded: null },
                { graded: { $exists: false } }
            ]
        };

        // Filtrar por materia concreta
        if (subject) {
            const rx = makeAccentInsensitiveRegex(subject);
            if (rx) filter.subject = rx;
        } else if (teacherId) {
            // ── BÚSQUEDA DUAL DE MATERIAS DEL DOCENTE ────────────────
            // Sistema 1: modelo Materia (asignación formal desde panel admin)
            // Sistema 2: campo User.materias (String CSV, asignación manual)
            // Se combinan ambas listas para máxima compatibilidad.
            const Materia = require('../models/Materia');

            const [teacher, assignedMaterias] = await Promise.all([
                User.findById(teacherId).select('materias'),
                Materia.find({ docenteId: teacherId, activa: true }).select('nombre')
            ]);

            // Materias desde el modelo formal Materia (panel admin)
            const fromMateriaModel = assignedMaterias.map(m => m.nombre.trim()).filter(Boolean);

            // Materias desde el campo String CSV del usuario (fallback/manual)
            const fromUserField = (teacher && teacher.materias && teacher.materias.trim() !== '')
                ? teacher.materias.split(',').map(s => s.trim()).filter(Boolean)
                : [];

            // Unión de ambas fuentes sin duplicados
            const teacherSubjects = [...new Set([...fromMateriaModel, ...fromUserField])];

            console.log(`👩‍🏫 Docente ${teacherId} — materias (modelo): [${fromMateriaModel.join(', ')}] — materias (campo): [${fromUserField.join(', ')}]`);

            if (teacherSubjects.length > 0) {
                // Generar expresiones regulares tolerantes a acentos para cada materia del docente
                const regexes = teacherSubjects.map(s => makeAccentInsensitiveRegex(s)).filter(Boolean);
                // Incluir también tareas sin materia para que ninguna tarea quede oculta ni traspapelada
                filter.subject = { $in: [...regexes, null, '', undefined] };
            }
            // Si el docente no tiene materias asignadas en NINGÚN sistema,
            // devolver TODAS las tareas entregadas (visibilidad total)
        }

        // Buscar items de agenda con PDF entregado
        const items = await Agenda.find(filter, {
            'pdfSubmission.fileBase64': 0   // Excluir el binario del PDF si existe (compatibilidad)
        })
        .sort({ 'pdfSubmission.submittedAt': -1 })
        .lean();

        // Enriquecer con datos del estudiante (nombre, grado, email)
        const User_model = require('../models/User');
        const userIds = [...new Set(items.map(i => i.userId))];
        const users = await User_model.find(
            { _id: { $in: userIds } },
            'name email grade'
        ).lean();
        const userMap = {};
        users.forEach(u => { userMap[u._id.toString()] = u; });

        const enriched = items.map(item => ({
            ...item,
            updated_at: item.pdfSubmission?.submittedAt || item.created_at,
            userId: userMap[item.userId] || { name: 'Estudiante', email: '', grade: '' },
        }));

        console.log(`👩‍🏫 Docente (${teacherId || 'sin ID'}) consultó ${enriched.length} tareas entregadas (agenda)`);
        res.json(enriched);
    } catch (error) {
        console.error('❌ Error al obtener tareas entregadas de agenda:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── GET /api/agenda/:id/pdf ─────────────────────────────────
// (ROL DOCENTE) Devuelve el PDF adjunto de un item de agenda.
// IMPORTANTE: debe ir ANTES de /:userId para que Express no confunda
// el segmento "<id>/pdf" con un userId.
router.get('/:id/pdf', async (req, res) => {
    try {
        const item = await Agenda.findById(req.params.id);
        if (!item) return res.status(404).json({ error: 'Item de agenda no encontrado' });

        if (!item.pdfSubmission) {
            return res.status(404).json({ error: 'Esta tarea no tiene PDF adjunto' });
        }

        const sub = item.pdfSubmission;

        // ── NUEVO: PDF guardado en disco ─────────────────────
        if (sub.filePath) {
            const absPath = path.resolve(sub.filePath);
            if (!fs.existsSync(absPath)) {
                return res.status(404).json({ error: 'El archivo PDF no se encontró en el servidor' });
            }
            console.log(`📄 Enviando PDF desde disco: ${absPath}`);
            res.setHeader('Content-Type', 'application/pdf');
            res.setHeader('Content-Disposition', `inline; filename="${sub.fileName}"`);
            return fs.createReadStream(absPath).pipe(res);
        }

        // ── LEGADO: PDF guardado como Base64 en MongoDB ──────
        if (sub.fileBase64) {
            console.log(`📄 Enviando PDF como Base64 (legado): ${req.params.id}`);
            return res.json({
                fileName:   sub.fileName,
                fileUrl:    `data:application/pdf;base64,${sub.fileBase64}`,
                note:       sub.note,
                uploadedAt: sub.submittedAt
            });
        }

        return res.status(404).json({ error: 'Esta tarea no tiene PDF adjunto' });
    } catch (error) {
        console.error('❌ Error al obtener PDF de agenda:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── GET /api/agenda/graded-by-teacher/:teacherId ────────────
// (ROL DOCENTE) Devuelve todas las tareas de agenda calificadas
// por el docente especificado, ordenadas por fecha de calificación.
// IMPORTANTE: debe ir ANTES de /:userId para evitar colisión de rutas.
router.get('/graded-by-teacher/:teacherId', async (req, res) => {
    try {
        const { teacherId } = req.params;

        const items = await Agenda.find(
            {
                graded: true,
                'grading.teacherId': teacherId,
                'grading.grade': { $exists: true, $ne: null }
            },
            { 'pdfSubmission.fileBase64': 0 }  // Excluir binario pesado
        )
        .sort({ 'grading.gradedAt': -1 })
        .lean();

        // Enriquecer con datos del estudiante
        const User_model = require('../models/User');
        const userIds = [...new Set(items.map(i => i.userId).filter(Boolean))];
        const users = await User_model.find(
            { _id: { $in: userIds } },
            'name email grade'
        ).lean();
        const userMap = {};
        users.forEach(u => { userMap[u._id.toString()] = u; });

        // Mapear al formato esperado por la pantalla TeacherGradeHistoryScreen
        const enriched = items.map(item => ({
            _id:            item._id,
            title:          item.title,
            subject:        item.subject || 'Sin materia',
            grade:          item.grading?.grade,
            teacherComment: item.grading?.teacherComment || '',
            gradedAt:       item.grading?.gradedAt,
            userId:         userMap[item.userId] || { name: 'Estudiante', email: '', grade: '' },
        }));

        console.log(`📊 Docente ${teacherId} — historial: ${enriched.length} tareas calificadas`);
        res.json(enriched);
    } catch (error) {
        console.error('❌ Error al obtener historial de calificaciones:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── GET /api/agenda/graded ──────────────────────────────────
// (ROL ADMIN — Panel Web) Devuelve TODAS las tareas de agenda
// calificadas por algún docente (graded: true o grading.grade != null).
// IMPORTANTE: debe ir ANTES de /:userId.
router.get('/graded', async (req, res) => {
    try {
        const filter = {
            $or: [
                { graded: true },
                { 'grading.grade': { $exists: true, $ne: null } }
            ]
        };

        const items = await Agenda.find(filter, {
            'pdfSubmission.fileBase64': 0 // Excluir PDF pesado
        })
        .sort({ 'grading.gradedAt': -1, created_at: -1 })
        .lean();

        const User_model = require('../models/User');
        const userIds = [...new Set(items.map(i => i.userId).filter(Boolean))];
        const teacherIds = [...new Set(items.map(i => i.grading?.teacherId).filter(Boolean))];

        const allIds = [...new Set([...userIds, ...teacherIds])];
        const users = await User_model.find(
            { _id: { $in: allIds } },
            'name email grade'
        ).lean();

        const userMap = {};
        users.forEach(u => { userMap[u._id.toString()] = u; });

        const enriched = items.map(item => ({
            _id: item._id,
            title: item.title,
            subject: item.subject || 'Sin materia',
            grade: item.grading?.grade,
            teacherComment: item.grading?.teacherComment || '',
            gradedAt: item.grading?.gradedAt,
            userId: userMap[item.userId] || { name: 'Estudiante', email: '' },
            gradedBy: userMap[item.grading?.teacherId] || (item.grading?.teacherId ? { name: 'Docente' } : null),
        }));

        console.log(`📊 Panel Admin: ${enriched.length} tareas calificadas encontradas (agenda)`);
        res.json(enriched);
    } catch (error) {
        console.error('❌ Error al obtener calificaciones de agenda:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── GET /api/agenda/:userId ─────────────────────────────────
// Devuelve todos los eventos de agenda de un usuario específico,
// ordenados por fecha ascendente (el más próximo primero).
// NOTA: Se excluye pdfSubmission.fileBase64 para no enviar archivos
//       gigantes en el listado y evitar que la conexión se cierre.
router.get('/:userId', async (req, res) => {
    try {
        const agenda = await Agenda.find(
            { userId: req.params.userId },
            { 'pdfSubmission.fileBase64': 0 }  // Excluir el PDF en Base64 (muy pesado)
        ).sort({ date: 1 }).lean();             // .lean() devuelve JS puro, más rápido

        res.json(agenda);
    } catch (error) {
        console.error('❌ Error al cargar agenda:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── POST /api/agenda/ ───────────────────────────────────────
// Crea un nuevo evento en la agenda del usuario.
// Body requerido: userId, title, date
// Body opcional:  description, type, imageUrl
router.post('/', async (req, res) => {
    try {
        const { userId, title, description, date, type, imageUrl } = req.body;
        console.log(`📥 Creando item de agenda para usuario: ${userId}`);

        const agendaItem = new Agenda({ userId, title, description, date, type, imageUrl });
        await agendaItem.save();

        console.log('✅ Item de agenda guardado con éxito');
        res.status(201).json(agendaItem);
    } catch (error) {
        console.error('❌ Error al guardar en agenda:', error.message);
        res.status(400).json({ error: error.message });
    }
});

// ── POST /api/agenda/:id/submit-pdf ────────────────────────
// Permite al estudiante entregar un PDF para un item de agenda
// de tipo 'homework'. Almacena el PDF en Base64 en el campo
// pdfSubmission del documento de agenda.
//
// Body: multipart/form-data
//   - pdf  (File)   : Archivo PDF obligatorio
//   - note (String) : Nota del estudiante (opcional)
router.post('/:id/submit-pdf', (req, res, next) => {
    // Manejamos el error de multer aquí para devolver JSON limpio al cliente
    upload.single('pdf')(req, res, (err) => {
        if (err) {
            if (err.code === 'LIMIT_FILE_SIZE') {
                return res.status(413).json({ error: 'El archivo PDF es demasiado grande. El tamaño máximo permitido es 50 MB.' });
            }
            return res.status(400).json({ error: err.message || 'Error al procesar el archivo' });
        }
        next();
    });
}, async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No se recibió ningún archivo PDF' });
        }

        const item = await Agenda.findById(req.params.id);
        if (!item) {
            // Si el item no existe, eliminar el archivo subido para no dejar basura
            fs.unlink(req.file.path, () => {});
            return res.status(404).json({ error: 'Evento de agenda no encontrado' });
        }

        if (item.type !== 'homework') {
            fs.unlink(req.file.path, () => {});
            return res.status(400).json({ error: 'Solo se pueden entregar PDFs para tareas (homework)' });
        }

        // Si ya había un PDF anterior, eliminar el archivo viejo del disco
        if (item.pdfSubmission && item.pdfSubmission.filePath) {
            const oldPath = path.resolve(item.pdfSubmission.filePath);
            if (fs.existsSync(oldPath)) fs.unlink(oldPath, () => {});
        }

        // Guardar SOLO la ruta del archivo en MongoDB (no el Base64)
        // Esto evita el límite de 16 MB por documento de MongoDB BSON.
        item.pdfSubmission = {
            fileName:    req.file.originalname || `tarea_${Date.now()}.pdf`,
            filePath:    req.file.path,          // Ruta en disco
            fileSize:    req.file.size,           // Tamaño en bytes
            note:        req.body.note || '',
            submittedAt: new Date()
        };

        // Guardar la materia si viene en el body
        if (req.body.subject && req.body.subject.trim()) {
            item.subject = req.body.subject.trim();
        }

        item.graded = false;  // Asegurarse de que está sin calificar
        await item.save();
        console.log(`📄 PDF guardado en disco: ${req.file.path} (${(req.file.size / 1024 / 1024).toFixed(2)} MB)`);

        // ── Enviar notificación push de confirmación al estudiante ──
        try {
            const admin = require('firebase-admin');
            const UserToken = require('../models/UserToken');
            const tokens = await UserToken.find({ userId: item.userId });
            if (tokens.length > 0) {
                const fcmTokens = tokens.map(t => t.fcmToken);
                const message = {
                    notification: {
                        title: '✅ Entrega Confirmada',
                        body: `Tu tarea "${item.title}" ha sido entregada con éxito.`,
                    },
                    data: {
                        type: 'submit_confirm',
                        userId: item.userId,
                        agendaItemId: item._id.toString(),
                    },
                    tokens: fcmTokens,
                    android: {
                        priority: 'high',
                        notification: {
                            channelId: 'tareas_channel',
                            color: '#FFC107',
                            priority: 'max',
                            sound: 'default',
                        }
                    }
                };
                const response = await admin.messaging().sendEachForMulticast(message);
                console.log(`🔔 Notificación de confirmación enviada a ${response.successCount} dispositivos`);
            }
        } catch (notifErr) {
            console.error('⚠️ Error al enviar notificación de confirmación:', notifErr.message);
        }

        res.json({
            message: 'PDF entregado exitosamente',
            item: {
                _id:   item._id,
                title: item.title,
                type:  item.type,
                pdfSubmission: {
                    fileName:    item.pdfSubmission.fileName,
                    fileSize:    item.pdfSubmission.fileSize,
                    note:        item.pdfSubmission.note,
                    submittedAt: item.pdfSubmission.submittedAt
                }
            }
        });
    } catch (error) {
        // Si hubo error de BD, eliminar el archivo del disco para evitar basura
        if (req.file && req.file.path) fs.unlink(req.file.path, () => {});
        console.error('❌ Error al entregar PDF de agenda:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── PUT /api/agenda/:id ─────────────────────────────────────
// Edita un evento de agenda existente.
// Body opcional: title, description, date, type
router.put('/:id', async (req, res) => {
    try {
        const { title, description, date, type } = req.body;
        const updates = {};
        if (title       !== undefined) updates.title       = title;
        if (description !== undefined) updates.description = description;
        if (date        !== undefined) updates.date        = date;
        if (type        !== undefined) updates.type        = type;

        const item = await Agenda.findByIdAndUpdate(
            req.params.id,
            updates,
            { new: true, runValidators: true }
        );
        if (!item) return res.status(404).json({ error: 'Evento no encontrado' });

        console.log(`✏️ Evento de agenda editado: ${item._id}`);
        res.json(item);
    } catch (error) {
        console.error('❌ Error al editar agenda:', error.message);
        res.status(400).json({ error: error.message });
    }
});

// ── DELETE /api/agenda/:id ──────────────────────────────────
// Elimina un evento de agenda por ID.
router.delete('/:id', async (req, res) => {
    try {
        const item = await Agenda.findByIdAndDelete(req.params.id);
        if (!item) return res.status(404).json({ error: 'Evento no encontrado' });
        console.log(`🗑️ Evento de agenda eliminado: ${req.params.id}`);
        res.json({ message: 'Evento eliminado correctamente' });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// NOTA: La ruta GET /:id/pdf fue movida ANTES de GET /:userId
// para evitar que Express la capture como si fuera un userId.
// Ver la definición arriba (línea ~116).

// ── PUT /api/agenda/:id/grade ────────────────────────────
// (ROL DOCENTE) Califica una tarea de agenda entregada.
// Body: grade (0-100), teacherId, teacherComment (opcional)
router.put('/:id/grade', async (req, res) => {
    try {
        const { grade, teacherComment, teacherId } = req.body;

        if (grade === undefined || grade === null) {
            return res.status(400).json({ error: 'La nota (grade) es obligatoria' });
        }
        const numericGrade = Number(grade);
        if (isNaN(numericGrade) || numericGrade < 0 || numericGrade > 100) {
            return res.status(400).json({ error: 'La nota debe ser un número entre 0 y 100' });
        }

        const item = await Agenda.findById(req.params.id);
        if (!item) return res.status(404).json({ error: 'Item de agenda no encontrado' });

        item.grading = {
            grade:          numericGrade,
            teacherComment: teacherComment || '',
            teacherId:      teacherId,
            gradedAt:       new Date()
        };
        item.graded       = true;
        item.is_completed = true;

        await item.save();
        console.log(`✅ Item de agenda ${item._id} calificado con nota ${numericGrade}/100`);

        res.json({ message: 'Tarea calificada exitosamente', item: {
            _id:    item._id,
            title:  item.title,
            graded: item.graded,
            grading: item.grading
        }});
    } catch (error) {
        console.error('❌ Error al calificar item de agenda:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── Exportar el router ──────────────────────────────────────
// server.js lo monta bajo el prefijo /api/agenda
module.exports = router;
