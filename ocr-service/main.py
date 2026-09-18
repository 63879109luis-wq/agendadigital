# ============================================================
# main.py — Servidor FastAPI del servicio OCR
# ============================================================
# Este archivo es el punto de entrada del microservicio OCR.
# Recibe imágenes de la app Flutter, las procesa con Tesseract
# y guarda los resultados en MongoDB a través del backend Node.js.
#
# Arquitectura:
#   App Flutter → POST /extract-text/ → (este servicio)
#                                          ↓ Tesseract OCR
#                                          ↓ POST /api/ocr → Backend Node.js → MongoDB
#
# Puerto: 8000 (accesible en el emulador Android como 10.0.2.2:8000)
# ============================================================

import os          # Para leer variables de entorno (BACKEND_URL)
import base64      # Para convertir bytes de imagen a cadena Base64
import requests    # Para hacer peticiones HTTP al backend Node.js

# FastAPI: framework web moderno y rápido para Python
# File, UploadFile: para recibir archivos en formularios multipart
# Form: para recibir campos de texto en formularios multipart
from fastapi import FastAPI, File, UploadFile, Form

# CORS: permite peticiones desde cualquier origen (necesario para Flutter web)
from fastapi.middleware.cors import CORSMiddleware

import uvicorn                              # Servidor ASGI para ejecutar FastAPI
from ocr_engine import extract_text_from_image  # Función de OCR definida en ocr_engine.py

# ── Crear la aplicación FastAPI ─────────────────────────────
app = FastAPI(title="OCR Service - Colegio Germán Busch A", version="2.0.0")

# ── Configurar CORS ─────────────────────────────────────────
# Permite que cualquier origen pueda hacer peticiones a este servicio.
# allow_origins=["*"] → acepta peticiones de cualquier dominio/IP.
# En producción, se debería restringir a los orígenes conocidos.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # Permite todos los orígenes
    allow_credentials=True,   # Permite enviar cookies/headers de autenticación
    allow_methods=["*"],      # Permite todos los métodos HTTP (GET, POST, etc.)
    allow_headers=["*"],      # Permite todos los headers
)

# ── URL del backend Node.js ─────────────────────────────────
# Se lee de la variable de entorno BACKEND_URL.
# Si no está configurada, usa localhost:3001 por defecto.
BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:3001")


def save_ocr_to_backend(user_id: str, task_id: str | None, file_name: str,
                         image_bytes: bytes, ocr_result: dict):
    """
    Envía el resultado del OCR al backend Express para persistirlo en MongoDB.
    
    Esta función hace una petición HTTP POST al endpoint /api/ocr del backend.
    Si el OCR fue exitoso → POST /api/ocr
    Si el OCR falló      → POST /api/ocr/failed
    
    La imagen se convierte a Base64 para poder enviarla como texto JSON.
    
    Args:
        user_id:    ID del usuario que realizó el escaneo
        task_id:    ID de la tarea asociada (puede ser None)
        file_name:  Nombre original del archivo de imagen
        image_bytes: Bytes de la imagen original
        ocr_result: Diccionario con el resultado del OCR (de extract_text_from_image)
    
    Returns:
        dict con el documento guardado en MongoDB, o None si falló el envío
    """
    try:
        # Convertir la imagen a Base64 para poder enviarla en el cuerpo JSON
        # base64.b64encode() → bytes de base64
        # .decode("utf-8")   → convierte esos bytes a string legible
        image_b64 = base64.b64encode(image_bytes).decode("utf-8")

        # Construir el payload JSON con toda la información del escaneo
        payload = {
            "userId":   user_id,
            "taskId":   task_id,
            "originalImage": {
                "fileName":  file_name,
                "fileUrl":   f"data:image/jpeg;base64,{image_b64}",  # Data URL con Base64
                "mimeType":  "image/jpeg",
                "sizeBytes": len(image_bytes)  # Tamaño en bytes de la imagen
            },
            "recognizedText": ocr_result.get("text", ""),          # Texto extraído
            "language":       "es",                                  # Idioma español
            "confidence":     ocr_result.get("confidence", 0),      # % de confianza
            "extractedData":  ocr_result.get("extracted_data", {}), # Fechas, materias, keywords
            "ocrEngine":      "tesseract",                           # Motor usado
            "processingTimeMs": ocr_result.get("processing_time_ms", 0) # Tiempo en ms
        }

        # Elegir el endpoint según si el OCR fue exitoso o no
        if ocr_result.get("status") == "completed":
            # OCR exitoso → guardar el resultado completo
            r = requests.post(f"{BACKEND_URL}/api/ocr", json=payload, timeout=10)
        else:
            # OCR fallido → solo guardar el registro del fallo con el mensaje de error
            r = requests.post(f"{BACKEND_URL}/api/ocr/failed", json={
                "userId":        user_id,
                "originalImage": payload["originalImage"],
                "errorMessage":  ocr_result.get("error", "OCR failed")
            }, timeout=10)

        print(f"📤 OCR guardado en backend → status {r.status_code}")
        # Si la respuesta fue exitosa (2xx) → devolver el JSON de respuesta
        # r.ok es True para códigos 200-299
        return r.json() if r.ok else None

    except Exception as e:
        # No lanzar excepción si el guardado falla:
        # el usuario todavía recibe el resultado del OCR aunque no se guarde en BD
        print(f"⚠️  No se pudo guardar en backend: {e}")
        return None


# ── Endpoints de la API ─────────────────────────────────────

@app.get("/")
def read_root():
    """
    Endpoint de salud del servicio.
    Llamado por monitoreo o para verificar que el servicio está activo.
    Devuelve información básica del servicio.
    """
    return {
        "status":  "online",
        "service": "OCR Service - Colegio Germán Busch A",
        "version": "2.0.0",
        "backend": BACKEND_URL  # URL del backend al que reporta los resultados
    }


@app.post("/extract-text/")
async def extract_text(
    file:    UploadFile = File(...),          # Archivo de imagen (campo requerido del formulario)
    userId:  str = Form(default="guest"),     # ID del usuario (campo opcional del formulario)
    taskId:  str = Form(default=None)         # ID de tarea asociada (campo opcional del formulario)
):
    """
    Endpoint principal del servicio OCR.
    
    Recibe una imagen a través de un formulario multipart/form-data,
    la procesa con Tesseract OCR y guarda el resultado en MongoDB.
    
    Parámetros del formulario:
        file:   Imagen a procesar (JPEG, PNG, etc.) — REQUERIDO
        userId: ID del usuario en MongoDB — OPCIONAL (default: 'guest')
        taskId: ID de la tarea asociada — OPCIONAL
    
    Retorna un JSON con:
        filename:           Nombre del archivo procesado
        text:               Texto extraído de la imagen
        confidence:         % de confianza del reconocimiento (0-100)
        processing_time_ms: Cuántos ms tardó el procesamiento
        extracted_data:     { dates, subjects, keywords }
        status:             'completed' o 'failed'
        saved_id:           ID del documento guardado en MongoDB (o null si falló)
        error:              Mensaje de error (solo si status='failed')
    """
    # Verificar que se envió un archivo
    if not file:
        return {"error": "No se subió ningún archivo", "status": "failed"}

    # Leer los bytes de la imagen desde el upload
    # await porque es una operación asíncrona (I/O de red/disco)
    contents = await file.read()
    print(f"📸 Procesando: {file.filename} ({len(contents)} bytes) para usuario {userId}")

    # ── Paso 1: Procesar la imagen con el motor OCR ──────────
    # extract_text_from_image() está definida en ocr_engine.py
    ocr_result = extract_text_from_image(contents)

    # ── Paso 2: Persistir en MongoDB via el backend Node.js ──
    # Si esto falla, no detiene la respuesta al usuario.
    # taskId puede llegar como cadena "null" desde Flutter → convertir a None
    saved = save_ocr_to_backend(
        user_id   = userId,
        task_id   = taskId if taskId and taskId != "null" else None,
        file_name = file.filename or "imagen.jpg",
        image_bytes = contents,
        ocr_result  = ocr_result
    )

    # ── Paso 3: Construir y devolver la respuesta ────────────
    response = {
        "filename":           file.filename,
        "text":               ocr_result["text"],
        "confidence":         ocr_result["confidence"],
        "processing_time_ms": ocr_result["processing_time_ms"],
        "extracted_data":     ocr_result["extracted_data"],
        "status":             ocr_result["status"],
        # ID del documento guardado en MongoDB (None si el guardado falló)
        "saved_id":           saved.get("_id") if saved else None
    }

    # Incluir el mensaje de error solo si hubo uno
    if ocr_result.get("error"):
        response["error"] = ocr_result["error"]

    print(f"✅ OCR completado: {len(ocr_result['text'])} chars | confianza: {ocr_result['confidence']}%")
    return response


# ── Punto de entrada ────────────────────────────────────────
# Solo se ejecuta cuando se corre directamente: python main.py
# En producción se usa: uvicorn main:app --host 0.0.0.0 --port 8000
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
    # host="0.0.0.0" → acepta conexiones desde cualquier interfaz de red
    # (necesario para ser accesible desde el emulador Android: 10.0.2.2:8000)
