// ============================================================
// routes/tasks.js — Rutas CRUD de tareas escolares
// ============================================================
// Gestiona el ciclo de vida completo de las tareas escolares:
// listar, ver detalle, crear, actualizar y eliminar.
// Cada operación también registra un evento en el Historial.
//
// Rutas disponibles:
//   GET    /api/tasks/:userId         → Listar tareas (con filtros opcionales)
//   GET    /api/tasks/detail/:id      → Ver detalle de una tarea específica
//   POST   /api/tasks/               → Crear nueva tarea
//   PUT    /api/tasks/:id            → Actualizar/completar una tarea
//   DELETE /api/tasks/:id            → Eliminar una tarea
// ============================================================

const express = require('express');
const router  = express.Router();
const Task    = require('../models/Task');
const User    = require('../models/User');    // Para buscar las materias del docente
const History = require('../models/History'); // Para registrar acciones en el log de actividad
const multer  = require('multer');            // Para manejar archivos multipart (PDF)

// Configuración de multer: almacena el PDF en memoria (Buffer)
const storage = multer.memoryStorage();
const upload  = multer({
    storage,
    limits: { fileSize: 50 * 1024 * 1024 }, // Máximo 50 MB
    fileFilter: (req, file, cb) => {
        if (file.mimetype === 'application/pdf') {
            cb(null, true);
        } else {
            cb(new Error('Solo se permiten archivos PDF'), false);
        }
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

// ── GET /api/tasks/submitted ────────────────────────────────
// (ROL DOCENTE) Devuelve todas las tareas entregadas por estudiantes
// que están pendientes de calificación (status: 'in_progress').
// IMPORTANTE: esta ruta debe ir ANTES de /:userId para que Express
// no interprete la palabra "submitted" como un userId.
// Admite filtros opcionales:
//   ?grade=5A            → Filtrar por grado escolar del estudiante
//   ?subject=Matemáticas → Filtrar por materia
//   ?teacherId=xxx       → Filtrar SOLO por las materias asignadas al docente
router.get('/submitted', async (req, res) => {
    try {
        const { grade, subject, teacherId } = req.query;

        // Filtrar tareas entregadas (PDF subido, esperando calificación)
        const filter = { status: 'in_progress' };

        // Si se especifica una materia concreta en el filtro, usarla directamente
        if (subject) {
            const rx = makeAccentInsensitiveRegex(subject);
            if (rx) filter.subject = rx;
        } else if (teacherId) {
            // Validar que el teacherId sea un ObjectId válido de MongoDB
            // (evita el error "Cast to ObjectId failed" con IDs demo/inválidos)
            const mongoose = require('mongoose');
            if (!mongoose.Types.ObjectId.isValid(teacherId)) {
                console.warn(`⚠️  teacherId inválido recibido: "${teacherId}" — se ignora el filtro por docente`);
                const tasks = await Task.find(filter)
                    .sort({ updated_at: -1 })
                    .populate('userId', 'name email grade');
                return res.json(tasks);
            }

            const Materia = require('../models/Materia');
            const [teacher, assignedMaterias] = await Promise.all([
                User.findById(teacherId).select('materias'),
                Materia.find({ docenteId: teacherId, activa: true }).select('nombre')
            ]);

            const fromMateriaModel = assignedMaterias.map(m => m.nombre.trim()).filter(Boolean);
            const fromUserField = (teacher && teacher.materias && teacher.materias.trim() !== '')
                ? teacher.materias.split(',').map(s => s.trim()).filter(Boolean)
                : [];

            const teacherSubjects = [...new Set([...fromMateriaModel, ...fromUserField])];

            if (teacherSubjects.length > 0) {
                const regexes = teacherSubjects.map(s => makeAccentInsensitiveRegex(s)).filter(Boolean);
                filter.subject = { $in: [...regexes, null, '', undefined] };
            }
        }

        // Buscar tareas y popular los datos del estudiante (nombre, grado)
        let tasks = await Task.find(filter)
            .sort({ updated_at: -1 }) // Las más recientes primero
            .populate('userId', 'name email grade'); // Traer nombre y grado del estudiante

        // Filtrar por grado escolar del estudiante si se especificó
        if (grade) {
            tasks = tasks.filter(t => t.userId && t.userId.grade === grade);
        }

        console.log(`👩‍🏫 Docente (${teacherId || 'sin ID'}) consultó ${tasks.length} tareas entregadas`);
        res.json(tasks);
    } catch (error) {
        console.error('❌ Error al obtener tareas entregadas:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── GET /api/tasks/graded ───────────────────────────────────
// (ROL ADMIN — Panel Web) Devuelve TODAS las tareas que ya han
// sido calificadas por algún docente (tienen el campo grade definido).
// Muestra el nombre del estudiante y el nombre del docente calificador.
// IMPORTANTE: debe ir ANTES de /:userId.
router.get('/graded', async (req, res) => {
    try {
        // Buscar todas las tareas donde grade está definido (calificadas por docente)
        const tasks = await Task.find({
            grade: { $exists: true, $ne: null }
        })
            .sort({ gradedAt: -1 }) // Más recientes primero
            .populate('userId',   'name email grade') // Datos del estudiante
            .populate('gradedBy', 'name email');       // Datos del docente calificador

        console.log(`📊 Panel Admin: ${tasks.length} tareas calificadas encontradas`);
        res.json(tasks);
    } catch (error) {
        console.error('❌ Error al obtener calificaciones:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── GET /api/tasks/graded-by-teacher/:teacherId ─────────────
// (ROL DOCENTE) Devuelve todas las tareas calificadas por un docente específico.
// Filtra por gradedBy === teacherId y las retorna ordenadas por fecha de calificación.
// Populadas con datos del estudiante (nombre, email, grade).
// IMPORTANTE: esta ruta debe ir ANTES de /:userId.
router.get('/graded-by-teacher/:teacherId', async (req, res) => {
    try {
        const { teacherId } = req.params;
        if (!teacherId) {
            return res.status(400).json({ error: 'teacherId es obligatorio' });
        }

        const tasks = await Task.find({
            gradedBy: teacherId,
            grade:    { $exists: true, $ne: null }
        })
            .sort({ gradedAt: -1 }) // Más recientes primero
            .populate('userId', 'name email grade'); // Datos del estudiante

        console.log(`📊 Docente ${teacherId}: ${tasks.length} tareas calificadas en historial`);
        res.json(tasks);
    } catch (error) {
        console.error('❌ Error al obtener historial de calificaciones:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── GET /api/tasks/:userId ──────────────────────────────────
// Devuelve todas las tareas de un usuario.
// Admite filtros opcionales por query string:
//   ?status=pending   → Solo tareas pendientes
//   ?type=exam        → Solo exámenes
//   ?from=2025-01-01  → Tareas con fecha de entrega desde esta fecha
//   ?to=2025-12-31    → Tareas con fecha de entrega hasta esta fecha
router.get('/:userId', async (req, res) => {

    try {
        const { status, type, from, to } = req.query;

        // Construir el filtro dinámicamente según los parámetros recibidos
        const filter = { userId: req.params.userId }; // Siempre filtra por usuario

        if (status) filter.status = status; // Añadir filtro de estado si se envió
        if (type)   filter.type   = type;   // Añadir filtro de tipo si se envió

        // Filtro de rango de fechas (operadores $gte = mayor o igual, $lte = menor o igual)
        if (from || to) {
            filter.dueDate = {};
            if (from) filter.dueDate.$gte = new Date(from); // Fecha mínima
            if (to)   filter.dueDate.$lte = new Date(to);   // Fecha máxima
        }

        // Buscar tareas con el filtro construido.
        // .sort({ dueDate: 1, created_at: -1 }) → primero las que vencen antes,
        //                                          y entre las sin fecha, las más recientes primero
        const tasks = await Task.find(filter).sort({ dueDate: 1, created_at: -1 });
        res.json(tasks);
    } catch (error) {
        console.error('❌ Error al obtener tareas:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── GET /api/tasks/detail/:id ───────────────────────────────
// Devuelve una sola tarea por su ID de MongoDB.
// .populate('ocrResultId') → Reemplaza el ID del OCR por el documento completo,
// permitiendo ver el texto escaneado vinculado directamente en la respuesta.
router.get('/detail/:id', async (req, res) => {
    try {
        const task = await Task.findById(req.params.id).populate('ocrResultId');
        if (!task) return res.status(404).json({ error: 'Tarea no encontrada' });
        res.json(task);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ── POST /api/tasks/ ────────────────────────────────────────
// Crea una nueva tarea y registra el evento en el historial.
// Body requerido: userId, title
// Body opcional:  description, subject, dueDate, reminderDate,
//                 priority, type, attachments, ocrResultId, tags
router.post('/', async (req, res) => {
    try {
        const {
            userId, title, description, subject,
            dueDate, reminderDate, priority, type,
            attachments, ocrResultId, tags
        } = req.body;

        console.log(`📥 Creando tarea: "${title}" para usuario ${userId}`);

        // Crear e insertar la tarea en MongoDB
        const task = new Task({
            userId, title, description, subject,
            dueDate, reminderDate, priority, type,
            attachments, ocrResultId, tags
        });

        await task.save(); // Dispara el middleware pre-save que actualiza updated_at

        // Registrar la acción en el historial de actividades del usuario
        await History.create({
            userId,
            action:       'task_create',
            resourceType: 'Task',
            resourceId:   task._id,                     // ID de la tarea recién creada
            description:  `Tarea creada: "${title}"`    // Descripción legible
        });

        console.log(`✅ Tarea guardada: ${task._id}`);
        res.status(201).json(task);
    } catch (error) {
        console.error('❌ Error al crear tarea:', error.message);
        res.status(400).json({ error: error.message });
    }
});

// ── PUT /api/tasks/:id ──────────────────────────────────────
// Actualiza campos de una tarea existente.
// Si is_completed=true o status='completed', también registra
// la fecha de completado y usa la acción 'task_complete' en el historial.
// Body: cualquier campo del esquema Task que se quiera modificar.
router.put('/:id', async (req, res) => {
    try {
        const updates = req.body;
        updates.updated_at = new Date(); // Actualizar timestamp de modificación manualmente

        // Detectar si la tarea se está marcando como completada
        // (puede venir de dos formas: is_completed:true o status:'completed')
        if (updates.is_completed === true || updates.status === 'completed') {
            updates.status       = 'completed';
            updates.is_completed = true;
            updates.completed_at = new Date(); // Registrar cuándo exactamente se completó
        }

        // findByIdAndUpdate + { new: true } devuelve el documento YA actualizado
        // (sin { new: true } devuelve la versión anterior al update)
        const task = await Task.findByIdAndUpdate(req.params.id, updates, { new: true });
        if (!task) return res.status(404).json({ error: 'Tarea no encontrada' });

        // Elegir la acción de historial según si se completó o solo se actualizó
        const action = (updates.is_completed) ? 'task_complete' : 'task_update';
        await History.create({
            userId:       task.userId,
            action,
            resourceType: 'Task',
            resourceId:   task._id,
            description:  `Tarea ${action === 'task_complete' ? 'completada' : 'actualizada'}: "${task.title}"`
        });

        console.log(`✅ Tarea actualizada: ${task._id}`);
        res.json(task);
    } catch (error) {
        console.error('❌ Error al actualizar tarea:', error.message);
        res.status(400).json({ error: error.message });
    }
});

// ── DELETE /api/tasks/:id ───────────────────────────────────
// Elimina permanentemente una tarea por su ID y registra el evento.
// Primero busca la tarea (para tener su data para el historial),
// luego la elimina y registra la acción.
router.delete('/:id', async (req, res) => {
    try {
        // findByIdAndDelete → busca, elimina y devuelve el documento eliminado
        const task = await Task.findByIdAndDelete(req.params.id);
        if (!task) return res.status(404).json({ error: 'Tarea no encontrada' });

        // Registrar la eliminación en el historial
        await History.create({
            userId:       task.userId,
            action:       'task_delete',
            resourceType: 'Task',
            resourceId:   task._id,
            description:  `Tarea eliminada: "${task.title}"`
        });

        console.log(`🗑️ Tarea eliminada: ${task._id}`);
        res.json({ message: 'Tarea eliminada correctamente', id: task._id });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ── POST /api/tasks/:id/submit-pdf ─────────────────────────
// Permite al estudiante entregar una tarea subiendo un archivo PDF.
// El PDF se almacena como Base64 en el array attachments de la tarea.
// También cambia el estado a 'in_progress' (entregado, pendiente de revisión).
//
// Body: multipart/form-data
//   - pdf  (File)   : Archivo PDF obligatorio
//   - note (String) : Nota/comentario del estudiante (opcional)
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

        const task = await Task.findById(req.params.id);
        if (!task) return res.status(404).json({ error: 'Tarea no encontrada' });

        // Convertir el buffer del PDF a Base64 para almacenarlo en MongoDB
        const pdfBase64 = req.file.buffer.toString('base64');

        // Crear el adjunto
        const attachment = {
            fileName:   req.file.originalname || `tarea_${Date.now()}.pdf`,
            fileUrl:    `data:application/pdf;base64,${pdfBase64}`,
            fileType:   'pdf',
            uploadedAt: new Date()
        };

        // Agregar el adjunto y actualizar el estado
        task.attachments.push(attachment);
        task.status     = 'in_progress';   // Entregado, pendiente de calificación
        task.updated_at = new Date();

        // Si viene nota del estudiante, añadirla a la descripción
        if (req.body.note && req.body.note.trim()) {
            task.description = (task.description ? task.description + '\n\n' : '')
                + `📎 Nota del estudiante: ${req.body.note.trim()}`;
        }

        await task.save();

        // Registrar en historial
        await History.create({
            userId:       task.userId,
            action:       'task_submit',
            resourceType: 'Task',
            resourceId:   task._id,
            description:  `PDF entregado para: "${task.title}"`
        });

        console.log(`📄 PDF entregado para tarea: ${task._id}`);

        // Devolver tarea actualizada SIN el base64 (demasiado grande para la respuesta)
        const taskObj = task.toObject();
        taskObj.attachments = taskObj.attachments.map(a => ({
            ...a,
            fileUrl: a.fileType === 'pdf' ? '[PDF guardado]' : a.fileUrl
        }));
        res.json({ message: 'PDF entregado exitosamente', task: taskObj });

    } catch (error) {
        console.error('❌ Error al entregar PDF:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── PUT /api/tasks/:id/grade ────────────────────────────────
// (ROL DOCENTE) Califica una tarea entregada.
// Cambia el status a 'completed' y registra la nota, comentario y quién calificó.
//
// Body requerido:
//   grade (Number 0-100) : Nota numérica
//   teacherId (String)   : ID del docente que califica
// Body opcional:
//   teacherComment (String) : Retroalimentación/comentario del docente
router.put('/:id/grade', async (req, res) => {
    try {
        const { grade, teacherComment, teacherId } = req.body;

        // Validar que la nota esté en el rango correcto
        if (grade === undefined || grade === null) {
            return res.status(400).json({ error: 'La nota (grade) es obligatoria' });
        }
        const numericGrade = Number(grade);
        if (isNaN(numericGrade) || numericGrade < 0 || numericGrade > 100) {
            return res.status(400).json({ error: 'La nota debe ser un número entre 0 y 100' });
        }

        const task = await Task.findById(req.params.id);
        if (!task) return res.status(404).json({ error: 'Tarea no encontrada' });

        // Aplicar la calificación
        task.grade          = numericGrade;
        task.teacherComment = teacherComment || '';
        task.gradedBy       = teacherId;
        task.gradedAt       = new Date();
        task.status         = 'completed';
        task.is_completed   = true;
        task.completed_at   = new Date();
        task.updated_at     = new Date();

        await task.save();

        // Registrar en historial
        await History.create({
            userId:       task.userId,
            action:       'task_complete',
            resourceType: 'Task',
            resourceId:   task._id,
            description:  `Tarea calificada: "${task.title}" — Nota: ${numericGrade}/100`
        });

        console.log(`✅ Tarea ${task._id} calificada con nota ${numericGrade}/100`);

        // Devolver tarea actualizada sin base64 de adjuntos
        const taskObj = task.toObject();
        taskObj.attachments = (taskObj.attachments || []).map(a => ({
            ...a,
            fileUrl: a.fileType === 'pdf' ? '[PDF guardado]' : a.fileUrl
        }));
        res.json({ message: 'Tarea calificada exitosamente', task: taskObj });

    } catch (error) {
        console.error('❌ Error al calificar tarea:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── GET /api/tasks/:id/pdf ──────────────────────────────────
// (ROL DOCENTE) Descarga el PDF adjunto de una tarea para revisión.
// Devuelve el primer adjunto PDF en base64 para que el docente lo visualice.
router.get('/:id/pdf', async (req, res) => {
    try {
        const task = await Task.findById(req.params.id);
        if (!task) return res.status(404).json({ error: 'Tarea no encontrada' });

        const pdfAttachment = (task.attachments || []).find(a => a.fileType === 'pdf');
        if (!pdfAttachment) {
            return res.status(404).json({ error: 'Esta tarea no tiene PDF adjunto' });
        }

        res.json({
            fileName: pdfAttachment.fileName,
            fileUrl:  pdfAttachment.fileUrl,   // data:application/pdf;base64,...
            uploadedAt: pdfAttachment.uploadedAt
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ── Exportar el router ──────────────────────────────────────
// server.js lo monta bajo el prefijo /api/tasks
module.exports = router;
