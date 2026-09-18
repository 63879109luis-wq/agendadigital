// ============================================================
// routes/ocr.js — Rutas para gestión de resultados OCR
// ============================================================
// El servicio Python (Tesseract) procesa las imágenes y luego
// llama a estas rutas para persistir los resultados en MongoDB.
// La app Flutter también usa estas rutas para leer el historial.
//
// Rutas disponibles:
//   GET    /api/ocr/:userId      → Historial de escaneos del usuario
//   GET    /api/ocr/detail/:id   → Detalle completo de un resultado (con imagen)
//   POST   /api/ocr/             → Guardar resultado exitoso
//   POST   /api/ocr/failed       → Registrar un escaneo fallido
//   DELETE /api/ocr/:id          → Eliminar un resultado
// ============================================================

const express   = require('express');
const router    = express.Router();
const OCRResult = require('../models/OCRResult');
const History   = require('../models/History'); // Para registrar el evento en el log de actividad

// ── GET /api/ocr/:userId ────────────────────────────────────
// Devuelve el historial de todos los escaneos de un usuario.
// NO incluye la imagen en Base64 (muy pesada) para no sobrecargar
// la respuesta de lista. Si se necesita la imagen, usar /detail/:id.
router.get('/:userId', async (req, res) => {
    try {
        const results = await OCRResult
            .find({ userId: req.params.userId }) // Solo resultados del usuario indicado
            .sort({ created_at: -1 })            // Más recientes primero
            .select('-originalImage.fileUrl');   // Excluir el campo fileUrl (Base64) del resultado
                                                 // para no enviar imágenes pesadas en el listado
        res.json(results);
    } catch (error) {
        console.error('❌ Error al obtener resultados OCR:', error.message);
        res.status(500).json({ error: error.message });
    }
});

// ── GET /api/ocr/detail/:id ─────────────────────────────────
// Devuelve UN resultado OCR completo por su ID, incluyendo
// la imagen original en Base64 (para mostrar la vista previa en la app).
router.get('/detail/:id', async (req, res) => {
    try {
        const result = await OCRResult.findById(req.params.id); // Buscar por ID de MongoDB
        if (!result) return res.status(404).json({ error: 'Resultado OCR no encontrado' });
        res.json(result); // Incluye todos los campos, incluyendo la imagen Base64
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ── POST /api/ocr/ ──────────────────────────────────────────
// Llamado por el servicio Python OCR cuando el escaneo fue EXITOSO.
// Guarda el resultado en MongoDB y registra el evento en el historial.
// Body requerido:
//   - userId, recognizedText
//   - originalImage: { fileName, fileUrl, mimeType, sizeBytes }
// Body opcional:
//   - taskId, language, confidence, extractedData, ocrEngine, processingTimeMs
router.post('/', async (req, res) => {
    try {
        const {
            userId,
            taskId,
            originalImage,      // Objeto con datos de la imagen original
            recognizedText,     // Texto completo extraído por Tesseract
            language,
            confidence,
            extractedData,      // { subjects, dates, keywords }
            ocrEngine,
            processingTimeMs
        } = req.body;

        console.log(`📸 Guardando resultado OCR para usuario: ${userId}`);

        // Crear e insertar el resultado en MongoDB
        const ocrResult = new OCRResult({
            userId,
            taskId,
            originalImage,
            recognizedText,
            language:         language        || 'es',         // Español por defecto
            confidence:       confidence      || null,
            extractedData:    extractedData   || {},
            ocrEngine:        ocrEngine       || 'tesseract',  // Motor por defecto
            processingTimeMs,
            status:           'completed'                      // Marcado como exitoso
        });

        await ocrResult.save();

        // Registrar en el historial de actividades
        await History.create({
            userId,
            action:       'ocr_complete',
            resourceType: 'OCRResult',
            resourceId:   ocrResult._id,
            // Descripción legible: nombre del archivo → cuántos caracteres se extrajeron
            description:  `OCR completado: ${originalImage?.fileName || 'imagen'} → ${recognizedText?.length || 0} caracteres`
        });

        console.log(`✅ OCR guardado: ${ocrResult._id} (${recognizedText?.length} chars)`);
        res.status(201).json(ocrResult);
    } catch (error) {
        console.error('❌ Error al guardar OCR:', error.message);
        res.status(400).json({ error: error.message });
    }
});

// ── POST /api/ocr/failed ────────────────────────────────────
// Llamado por el servicio Python OCR cuando el escaneo FALLÓ.
// Guarda un registro del intento fallido en MongoDB para mantener
// el historial completo y ayudar a diagnosticar problemas.
// Body requerido: userId, originalImage, errorMessage
router.post('/failed', async (req, res) => {
    try {
        const { userId, originalImage, errorMessage } = req.body;

        // Crear el registro con estado 'failed' y texto vacío
        const ocrResult = new OCRResult({
            userId,
            originalImage,
            recognizedText: '', // Sin texto porque falló
            status:         'failed',
            errorMessage    // Razón del fallo (ej: "Could not open image")
        });

        await ocrResult.save();

        // Registrar el fallo en el historial
        await History.create({
            userId,
            action:       'ocr_failed',
            resourceType: 'OCRResult',
            resourceId:   ocrResult._id,
            description:  `OCR fallido: ${errorMessage}`
        });

        res.status(201).json(ocrResult);
    } catch (error) {
        res.status(400).json({ error: error.message });
    }
});

// ── DELETE /api/ocr/:id ─────────────────────────────────────
// Elimina permanentemente un resultado OCR por su ID.
// El usuario puede limpiar su historial de escaneos.
router.delete('/:id', async (req, res) => {
    try {
        const result = await OCRResult.findByIdAndDelete(req.params.id);
        if (!result) return res.status(404).json({ error: 'Resultado OCR no encontrado' });

        console.log(`🗑️ OCR eliminado: ${result._id}`);
        res.json({ message: 'Resultado OCR eliminado', id: result._id });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// ── Exportar el router ──────────────────────────────────────
// server.js lo monta bajo el prefijo /api/ocr
module.exports = router;
