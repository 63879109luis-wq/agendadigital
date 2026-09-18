# ============================================================
# ocr_engine.py — Motor de reconocimiento de texto (OCR)
# ============================================================
# Contiene la función principal que recibe los bytes de una imagen
# y devuelve el texto extraído junto con metadatos de calidad.
# Utiliza Tesseract OCR (a través de pytesseract) configurado
# para el idioma español.
#
# Flujo:
#   1. Recibe bytes de imagen → los convierte a objeto PIL Image
#   2. Tesseract extrae texto y datos de confianza por palabra
#   3. Se calculan: texto limpio, confianza promedio
#   4. Se detectan automáticamente: fechas, materias escolares y keywords
#   5. Devuelve un dict con todos los resultados
# ============================================================

import pytesseract          # Wrapper Python para el motor OCR Tesseract
from PIL import Image       # Pillow: librería para abrir y procesar imágenes
import io                  # Para convertir bytes en objetos de archivo en memoria
import time                # Para medir el tiempo de procesamiento
import re                  # Expresiones regulares (detección de fechas y keywords)
from datetime import datetime

# Si Tesseract no está en el PATH del sistema, descomenta y ajusta la ruta:
# pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'


def extract_text_from_image(image_bytes: bytes) -> dict:
    """
    Función principal del motor OCR.
    
    Recibe una imagen en bytes y devuelve un diccionario con:
      - text:               Texto completo extraído de la imagen
      - confidence:         Porcentaje de confianza promedio (0-100)
      - processing_time_ms: Tiempo de procesamiento en milisegundos
      - extracted_data:     Datos estructurados encontrados:
                              - dates:    Fechas detectadas (formato dd/mm/yyyy)
                              - keywords: Palabras clave importantes (>4 letras)
                              - subjects: Materias escolares detectadas
      - status:             'completed' si se extrajo texto, 'failed' si no
      - error:              Mensaje de error si algo falló (None si todo OK)
    """
    # Registrar el tiempo de inicio para calcular duración del procesamiento
    start = time.time()

    # Inicializar el resultado con valores por defecto (en caso de que falle todo)
    result = {
        "text":               "",
        "confidence":         0,
        "processing_time_ms": 0,
        "extracted_data":     {"dates": [], "keywords": [], "subjects": []},
        "status":             "failed",  # Se cambia a 'completed' si hay éxito
        "error":              None,
    }

    try:
        # ── Paso 1: Convertir bytes → objeto PIL Image ──────────────
        # io.BytesIO crea un "archivo en memoria" desde los bytes,
        # así Pillow puede abrirlo sin necesidad de escribir al disco.
        image = Image.open(io.BytesIO(image_bytes))

        # ── Paso 2: Extraer datos de confianza por palabra ──────────
        # image_to_data() devuelve un dict con info por cada palabra detectada:
        # 'text', 'conf' (confianza -1 a 100), coordenadas, etc.
        # lang="spa" indica que el texto está en español (mejora la precisión).
        # Output.DICT devuelve los datos como diccionario Python.
        data = pytesseract.image_to_data(
            image, lang="spa", output_type=pytesseract.Output.DICT
        )

        # ── Paso 3: Calcular confianza promedio ─────────────────────
        # Tesseract asigna conf=-1 a espacios/ruido (no son palabras reales).
        # Filtramos los -1 y calculamos el promedio de los valores válidos (0-100).
        confidences    = [int(c) for c in data["conf"] if int(c) >= 0]
        avg_confidence = (
            round(sum(confidences) / len(confidences), 1) if confidences else 0
        )

        # ── Paso 4: Extraer texto limpio ────────────────────────────
        # image_to_string() devuelve el texto completo como un string.
        # .strip() elimina espacios y saltos de línea al inicio y al final.
        text = pytesseract.image_to_string(image, lang="spa").strip()

        # ── Paso 5: Detectar fechas en el texto ─────────────────────
        # Busca patrones de fecha con expresión regular:
        # \b        = límite de palabra (evita falsos positivos)
        # \d{1,2}   = 1 o 2 dígitos (día o mes)
        # [\/\-]    = separador / o -
        # \d{2,4}   = año con 2 o 4 dígitos
        # Detecta: 05/12/2025, 5-1-25, 15/01/2025, etc.
        date_pattern = r"\b(\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4})\b"
        dates_found  = re.findall(date_pattern, text)

        # ── Paso 6: Detectar materias escolares ─────────────────────
        # Lista de materias comunes en colegios bolivianos.
        # Se buscan como substrings en el texto en minúsculas.
        SUBJECTS = [
            "matematica", "matematicas", "lengua", "lenguaje",
            "historia", "ciencias", "fisica", "quimica", "biologia",
            "geografia", "ingles", "informatica", "computacion",
            "arte", "musica", "educacion", "civica", "religion", "filosofia",
        ]
        text_lower     = text.lower()  # Normalizar a minúsculas para comparación
        # Si la materia aparece en el texto → agregar capitalizada al resultado
        subjects_found = [s.capitalize() for s in SUBJECTS if s in text_lower]

        # ── Paso 7: Extraer palabras clave ──────────────────────────
        # Buscar palabras de más de 4 letras (español, incluyendo tildes y ñ).
        # [a-záéíóúñA-ZÁÉÍÓÚÑ]{5,} = letras del español con mínimo 5 caracteres.
        # list(set(...)) elimina duplicados.
        # [:15] limita a máximo 15 keywords para no saturar la respuesta.
        words    = re.findall(r"\b[a-záéíóúñA-ZÁÉÍÓÚÑ]{5,}\b", text)
        keywords = list(set(words[:15]))

        # ── Paso 8: Actualizar resultado con los datos extraídos ────
        result.update(
            {
                "text":               text,
                "confidence":         avg_confidence,
                "processing_time_ms": round((time.time() - start) * 1000),  # ms
                "extracted_data": {
                    "dates":    dates_found,
                    "keywords": keywords,
                    "subjects": subjects_found,
                },
                # Si se extrajo algo de texto → completed; si no → failed
                "status": "completed" if text else "failed",
            }
        )

    except Exception as e:
        # Capturar cualquier error (imagen corrupta, Tesseract no instalado, etc.)
        result["error"]              = str(e)
        result["processing_time_ms"] = round((time.time() - start) * 1000)
        print(f"❌ Error en OCR: {e}")

    return result
