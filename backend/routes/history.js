// ============================================================
// routes/history.js — Rutas del historial de actividades
// ============================================================
// Permite consultar y limpiar el registro de todas las acciones
// realizadas por un usuario en la aplicación.
// Soporta paginación y múltiples filtros para búsquedas precisas.
//
// Rutas disponibles:
//   GET    /api/history/:userId  → Obtener historial (con filtros y paginación)
//   DELETE /api/history/:userId  → Borrar TODO el historial del usuario
// ============================================================

const express = require('express');
const router  = express.Router();
const History = require('../models/History');

// ── GET /api/history/:userId ────────────────────────────────
// Devuelve el historial de actividades de un usuario con paginación.
// Parámetros de query opcionales:
//   ?action=task_create       → Filtrar por tipo de acción
//   ?resourceType=Task        → Filtrar por tipo de recurso
//   ?from=2025-01-01          → Solo eventos desde esta fecha
//   ?to=2025-12-31            → Solo eventos hasta esta fecha
//   ?page=1                   → Número de página (default: 1)
//   ?limit=50                 → Registros por página (default: 50)
//
// Respuesta: { total, page, pages, data: [...] }
router.get('/:userId', async (req, res) => {
    try {
        // Extraer parámetros de query con valores por defecto
        const { action, resourceType, from, to, limit = 50, page = 1 } = req.query;

        // Construir el filtro de búsqueda dinámicamente
        const filter = { userId: req.params.userId }; // Siempre filtrar por usuario

        if (action)       filter.action       = action;       // Filtrar por tipo de acción
        if (resourceType) filter.resourceType = resourceType; // Filtrar por tipo de recurso

        // Filtro de rango de fechas en el campo 'timestamp'
        if (from || to) {
            filter.timestamp = {};
            if (from) filter.timestamp.$gte = new Date(from); // Desde esta fecha
            if (to)   filter.timestamp.$lte = new Date(to);   // Hasta esta fecha
        }

        // ── Paginación ──────────────────────────────────────
        // skip: cuántos documentos saltar. Con page=2 y limit=50 → skip=50
        const skip  = (parseInt(page) - 1) * parseInt(limit);
        // Contar el total de documentos que cumplen el filtro (sin paginar)
        const total = await History.countDocuments(filter);

        // Ejecutar la consulta con paginación
        const history = await History
            .find(filter)
            .sort({ timestamp: -1 })      // Más recientes primero
            .skip(skip)                    // Saltar registros de páginas anteriores
            .limit(parseInt(limit));       // Limitar a N resultados por página

        // Devolver metadatos de paginación junto con los datos
        res.json({
            total,                              // Total de registros que coinciden con el filtro
            page:  parseInt(page),              // Página actual
            pages: Math.ceil(total / parseInt(limit)), // Total de páginas disponibles
            data:  history                      // Array de registros de esta página
        });
    } catch (error) {
        console.error('❌ Error al obtener historial:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── DELETE /api/history/:userId ─────────────────────────────
// Elimina TODOS los registros del historial de un usuario.
// Útil para que el usuario pueda limpiar su historial completo.
// deleteMany() elimina múltiples documentos a la vez.
router.delete('/:userId', async (req, res) => {
    try {
        // Eliminar todos los documentos donde userId === req.params.userId
        const result = await History.deleteMany({ userId: req.params.userId });

        console.log(`🗑️ Historial eliminado para usuario ${req.params.userId}: ${result.deletedCount} registros`);

        // Informar cuántos registros se eliminaron
        res.json({ message: `${result.deletedCount} registros eliminados del historial` });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ── Exportar el router ──────────────────────────────────────
// server.js lo monta bajo el prefijo /api/history
module.exports = router;
