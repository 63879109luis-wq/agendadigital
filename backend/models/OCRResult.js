// ============================================================
// models/OCRResult.js — Modelo de resultados del escáner OCR
// ============================================================
// Guarda en MongoDB los resultados de cada escaneo de imagen
// realizado por el servicio Python OCR (Tesseract).
// Incluye la imagen original, el texto extraído, la confianza
// y los datos estructurados detectados (fechas, materias, etc.).
// ============================================================

const mongoose = require('mongoose');

// ── Definir el esquema de resultado OCR ───────────────────
const OCRResultSchema = new mongoose.Schema({
    // Usuario que realizó el escaneo (referencia a la colección "users")
    userId: {
        type:     mongoose.Schema.Types.ObjectId,
        ref:      'User',
        required: true
    },

    // Tarea asociada al escaneo (opcional).
    // Si el usuario escaneó una imagen relacionada con una tarea, se vincula aquí.
    taskId: {
        type: mongoose.Schema.Types.ObjectId,
        ref:  'Task'
    },

    // ── Imagen original enviada al OCR ─────────────────────
    originalImage: {
        fileName:  { type: String },                       // Nombre del archivo (ej: "tarea.jpg")
        fileUrl:   { type: String },                       // URL en storage o cadena Base64 de la imagen
        filePath:  { type: String },                       // Ruta local en el servidor OCR (si aplica)
        mimeType:  { type: String, default: 'image/jpeg' }, // Tipo MIME del archivo
        sizeBytes: { type: Number }                        // Tamaño en bytes del archivo
    },

    // ── Texto extraído por Tesseract ───────────────────────
    recognizedText: {
        type:     String,    // Texto completo tal como lo extrajo el motor OCR
        required: true
    },

    // Idioma usado para el reconocimiento
    language: {
        type:    String,
        default: 'es'    // Por defecto español (configurado en el servicio Python)
    },

    // Porcentaje de confianza del reconocimiento (0 = muy malo, 100 = perfecto).
    // Es el promedio de la confianza por palabra que devuelve Tesseract.
    confidence: {
        type: Number,
        min:  0,
        max:  100
    },

    // ── Datos estructurados extraídos del texto ────────────
    // El servicio Python analiza el texto para detectar automáticamente:
    extractedData: {
        subjects:  [String],                          // Materias detectadas (ej: ["Matemáticas", "Historia"])
        dates:     [Date],                            // Fechas encontradas en el texto (ej: "15/05/2025")
        keywords:  [String],                          // Palabras clave importantes (más de 4 letras)
        rawBlocks: [mongoose.Schema.Types.Mixed]      // Datos crudos del motor OCR (bloques word-by-word)
    },

    // Motor OCR utilizado (por ahora siempre Tesseract, puede crecer a Google Vision)
    ocrEngine: {
        type:    String,
        default: 'tesseract'
    },

    processingTimeMs: { type: Number }, // Cuántos milisegundos tardó el procesamiento

    // Estado del proceso OCR
    status: {
        type:    String,
        enum:    ['pending', 'processing', 'completed', 'failed'],
        default: 'completed'
    },

    errorMessage: { type: String },                  // Mensaje de error si status === 'failed'
    created_at:   { type: Date, default: Date.now }  // Fecha de creación automática
});

// ── Exportar el modelo ──────────────────────────────────────
// Crea la colección "ocrresults" en MongoDB.
module.exports = mongoose.model('OCRResult', OCRResultSchema);
