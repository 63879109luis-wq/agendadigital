// ============================================================
// services/api_service.dart — Capa de comunicación con el backend
// ============================================================
// Este archivo centraliza TODAS las peticiones HTTP de la app Flutter
// hacia el backend Node.js (puerto 3001) y el servicio OCR Python (puerto 8000).
//
// Detecta automáticamente la plataforma para usar la URL correcta:
//   - Emulador Android → 10.0.2.2 (alias de localhost del host)
//   - Web / iOS / Desktop → 127.0.0.1
//
// Organización por secciones:
//   1. AUTH      → login, register
//   2. AGENDA    → getAgenda, saveAgendaItem
//   3. TAREAS    → getTasks, getTaskDetail, createTask, updateTask,
//                  completeTask, deleteTask
//   4. OCR       → scanImage, getOCRHistory, getOCRDetail, deleteOCRResult
//   5. HISTORIAL → getHistory
//   6. UNIVERSO  → getUniverse, resetUniverse, addPlanet
// ============================================================

import 'dart:convert';            // jsonEncode / jsonDecode para serializar JSON
import 'dart:io';                 // Platform (para detectar Android/iOS/Desktop)
import 'package:http/http.dart' as http;          // Cliente HTTP
import 'package:http_parser/http_parser.dart';    // MediaType (para archivos multipart)
import 'package:image_picker/image_picker.dart';  // XFile (archivo de imagen de la cámara)
import 'package:flutter/foundation.dart';         // kIsWeb (detectar si es web)

/// Servicio de API que gestiona toda la comunicación HTTP de la app.
/// Se instancia normalmente: final api = ApiService();
class ApiService {
  // ── URLs base por plataforma ────────────────────────────────
  // En Android el emulador usa 10.0.2.2 para referirse al localhost del PC.
  // En Web e iOS se usa 127.0.0.1 directamente.

  /// URL base del backend Node.js (Express) en puerto 3001
  static String get baseUrl {
    if (kIsWeb) return 'http://127.0.0.1:3001/api';           // Navegador web
    if (Platform.isAndroid) return 'http://10.0.2.2:3001/api'; // Emulador Android
    return 'http://127.0.0.1:3001/api';                        // iOS / Desktop
  }

  /// URL base del servicio Python OCR en puerto 8000
  static String get ocrUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://127.0.0.1:8000';
  }

  // ── Helper: encabezados para peticiones JSON ────────────────
  /// Headers estándar para peticiones con cuerpo JSON
  Map<String, String> get _jsonHeaders => {'Content-Type': 'application/json'};

  // ── Helper: verificación de errores HTTP ────────────────────
  /// Verifica si la respuesta HTTP tiene un código de error (>= 400).
  /// Si es así, lanza una excepción con el mensaje de error del servidor.
  /// [res] - La respuesta HTTP recibida
  /// [ctx] - Nombre del contexto (para mensajes de error más descriptivos)
  void _checkStatus(http.Response res, String ctx) {
    if (res.statusCode >= 400) {
      final body = jsonDecode(res.body);
      // El backend devuelve { "error": "mensaje" } en caso de error
      throw Exception(body['error'] ?? 'Error en $ctx (${res.statusCode})');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  SECCIÓN 1: AUTENTICACIÓN
  // ═══════════════════════════════════════════════════════════

  /// Inicia sesión con email y contraseña.
  /// Devuelve el documento del usuario desde MongoDB (sin contraseña).
  /// Lanza excepción si las credenciales son incorrectas o hay error de red.
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );
      _checkStatus(res, 'login');      // Lanza si status >= 400
      return jsonDecode(res.body);     // Devuelve el usuario como Map
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Registra un nuevo usuario en la base de datos.
  /// [userData] debe contener: name, email, password, role, grade (opcional)
  /// Devuelve el nuevo usuario creado.
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _jsonHeaders,
        body: jsonEncode(userData),
      );
      _checkStatus(res, 'register');
      return jsonDecode(res.body);
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  SECCIÓN 2: AGENDA
  // ═══════════════════════════════════════════════════════════

  /// Obtiene todos los eventos de agenda del usuario, ordenados por fecha.
  /// Devuelve una lista de eventos como Maps.
  Future<List<dynamic>> getAgenda(String userId) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl/agenda/$userId'))
          .timeout(const Duration(seconds: 30)); // Evita cuelgues indefinidos
      _checkStatus(res, 'getAgenda');
      return jsonDecode(res.body); // Lista de eventos
    } catch (e) {
      throw Exception('Error al cargar agenda: $e');
    }
  }

  /// Guarda un nuevo evento en la agenda del usuario.
  /// [data] debe contener: userId, title, date
  /// [data] puede contener: description, type, imageUrl
  Future<Map<String, dynamic>> saveAgendaItem(Map<String, dynamic> data) async {
    print('📡 Agenda → ${data['title']}');
    final res = await http.post(
      Uri.parse('$baseUrl/agenda'),
      headers: _jsonHeaders,
      body: jsonEncode(data),
    );
    _checkStatus(res, 'saveAgendaItem');
    return jsonDecode(res.body); // El evento recién creado
  }

  /// Actualiza un evento de agenda existente.
  /// [agendaId] - ID de MongoDB del evento a editar
  /// [updates]  - Map con los campos a modificar: title, description, date, type
  Future<Map<String, dynamic>> updateAgendaItem(
      String agendaId, Map<String, dynamic> updates) async {
    final res = await http.put(
      Uri.parse('$baseUrl/agenda/$agendaId'),
      headers: _jsonHeaders,
      body: jsonEncode(updates),
    );
    _checkStatus(res, 'updateAgendaItem');
    return jsonDecode(res.body); // El evento actualizado
  }

  /// Elimina un evento de agenda por su ID.
  Future<void> deleteAgendaItem(String agendaId) async {
    final res = await http.delete(Uri.parse('$baseUrl/agenda/$agendaId'));
    _checkStatus(res, 'deleteAgendaItem');
  }

  // ═══════════════════════════════════════════════════════════
  //  SECCIÓN 3: TAREAS ESCOLARES
  // ═══════════════════════════════════════════════════════════

  /// Obtiene todas las tareas de un usuario con filtros opcionales.
  /// 
  /// Parámetros opcionales:
  ///   [status] - Filtrar por estado: 'pending', 'completed', 'in_progress', 'overdue'
  ///   [type]   - Filtrar por tipo: 'homework', 'exam', 'project', 'reminder', 'other'
  ///   [from]   - Solo tareas con fecha de entrega desde esta fecha
  ///   [to]     - Solo tareas con fecha de entrega hasta esta fecha
  Future<List<dynamic>> getTasks(
    String userId, {
    String? status,
    String? type,
    DateTime? from,
    DateTime? to,
  }) async {
    // Construir parámetros de query dinámicamente
    final params = <String, String>{'userId': userId};
    if (status != null) params['status'] = status;
    if (type   != null) params['type']   = type;
    if (from   != null) params['from']   = from.toIso8601String(); // Formato ISO para el servidor
    if (to     != null) params['to']     = to.toIso8601String();

    // replace(queryParameters: ...) añade los filtros como ?status=pending&type=exam etc.
    final uri = Uri.parse('$baseUrl/tasks/$userId')
        .replace(queryParameters: params..remove('userId')); // userId ya está en la URL, no en query
    final res = await http.get(uri);
    _checkStatus(res, 'getTasks');
    return jsonDecode(res.body);
  }

  /// Obtiene una tarea específica por su ID con el resultado OCR vinculado.
  /// El backend hace populate() del ocrResultId, devolviendo el documento completo de OCR.
  Future<Map<String, dynamic>> getTaskDetail(String taskId) async {
    final res = await http.get(Uri.parse('$baseUrl/tasks/detail/$taskId'));
    _checkStatus(res, 'getTaskDetail');
    return jsonDecode(res.body);
  }

  /// Crea una nueva tarea escolar para el usuario.
  /// [data] requerido: userId, title
  /// [data] opcional:  description, subject, dueDate, reminderDate,
  ///                   priority, type, attachments, ocrResultId, tags
  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    print('📋 Creando tarea: ${data['title']}');
    final res = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: _jsonHeaders,
      body: jsonEncode(data),
    );
    _checkStatus(res, 'createTask');
    return jsonDecode(res.body); // La tarea recién creada
  }

  /// Actualiza campos parciales de una tarea existente.
  /// [taskId]  - ID de MongoDB de la tarea a actualizar
  /// [updates] - Map con los campos a modificar (solo los que cambian)
  Future<Map<String, dynamic>> updateTask(
      String taskId, Map<String, dynamic> updates) async {
    final res = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: _jsonHeaders,
      body: jsonEncode(updates),
    );
    _checkStatus(res, 'updateTask');
    return jsonDecode(res.body); // La tarea actualizada
  }

  /// Atajo para marcar una tarea como completada.
  /// Internamente llama a updateTask() con los campos de completado.
  Future<Map<String, dynamic>> completeTask(String taskId) =>
      updateTask(taskId, {'is_completed': true, 'status': 'completed'});

  /// Elimina permanentemente una tarea por su ID.
  Future<void> deleteTask(String taskId) async {
    final res = await http.delete(Uri.parse('$baseUrl/tasks/$taskId'));
    _checkStatus(res, 'deleteTask');
    // No devuelve nada (void) ya que el recurso fue eliminado
  }

  /// (ROL DOCENTE) Obtiene todas las tareas de agenda entregadas (con PDF) pendientes de calificación.
  /// El backend enriquece cada item con datos del estudiante (nombre, grado, email).
  ///
  /// Parámetros opcionales:
  ///   [subject]   - Filtrar por materia (ej: "Historia")
  ///   [teacherId] - Filtrar por materias asignadas al docente
  Future<List<dynamic>> getSubmittedAgendaTasks({
    String? subject,
    String? teacherId,
  }) async {
    final params = <String, String>{};
    if (subject   != null) params['subject']   = subject;
    if (teacherId != null) params['teacherId'] = teacherId;

    final uri = Uri.parse('$baseUrl/agenda/submitted')
        .replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    _checkStatus(res, 'getSubmittedAgendaTasks');
    return jsonDecode(res.body);
  }

  /// (ROL DOCENTE) Obtiene el PDF adjunto de un item de agenda para revisión.
  /// Soporta dos modos:
  ///   - Nuevo: el backend envía el PDF como stream binario → devuelve { pdfBytes: Uint8List }
  ///   - Legado: el backend envía JSON con fileUrl en Base64 → lo devuelve tal cual
  /// Usa timeout de 60 s para PDFs grandes.
  Future<Map<String, dynamic>> getAgendaItemPdf(String agendaItemId) async {
    final uri = Uri.parse('$baseUrl/agenda/$agendaItemId/pdf');
    final res = await http.get(uri).timeout(const Duration(seconds: 60));

    if (res.statusCode >= 400) {
      try {
        final body = jsonDecode(res.body);
        throw Exception(body['error'] ?? 'Error al obtener PDF (${res.statusCode})');
      } catch (_) {
        throw Exception('Error al obtener PDF (${res.statusCode})');
      }
    }

    final contentType = res.headers['content-type'] ?? '';

    // Nuevo sistema: el backend envía el PDF como bytes binarios
    if (contentType.contains('application/pdf')) {
      // Extraer nombre del archivo del header Content-Disposition si viene
      final disposition = res.headers['content-disposition'] ?? '';
      String fileName = 'tarea.pdf';
      if (disposition.contains('filename=')) {
        fileName = disposition
            .split('filename=')
            .last
            .replaceAll('"', '')
            .trim();
      }
      return {
        'pdfBytes':  res.bodyBytes,  // Uint8List con los bytes del PDF
        'fileName':  fileName,
        'fileUrl':   '',             // No hay Base64 en el nuevo sistema
        'uploadedAt': null,
        'note':      null,
      };
    }

    // Sistema legado: el backend devuelve JSON con Base64
    return jsonDecode(res.body);
  }

  /// (ROL DOCENTE) Califica una tarea de agenda entregada.
  /// El backend cambia graded a true y guarda la nota en el subdocumento grading.
  ///
  /// [agendaItemId] - ID de MongoDB del item de agenda a calificar
  /// [grade]        - Nota numérica (0–100)
  /// [teacherId]    - ID del docente que califica
  /// [comment]      - Retroalimentación del docente (opcional)
  Future<Map<String, dynamic>> gradeAgendaTask(
    String agendaItemId,
    int grade,
    String teacherId, {
    String comment = '',
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/agenda/$agendaItemId/grade'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'grade':          grade,
        'teacherComment': comment,
        'teacherId':      teacherId,
      }),
    );
    _checkStatus(res, 'gradeAgendaTask');
    return jsonDecode(res.body);
  }

  /// (ROL DOCENTE) Califica una tarea entregada.
  /// Envía la nota (0-100), un comentario opcional y el ID del docente.
  /// El backend cambia el status a 'completed'.
  ///
  /// [taskId]    - ID de MongoDB de la tarea a calificar
  /// [grade]     - Nota numérica (0–100)
  /// [comment]   - Retroalimentación del docente (opcional)
  /// [teacherId] - ID del docente que califica
  Future<Map<String, dynamic>> gradeTask(
    String taskId,
    int grade,
    String teacherId, {
    String comment = '',
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId/grade'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'grade':          grade,
        'teacherComment': comment,
        'teacherId':      teacherId,
      }),
    );
    _checkStatus(res, 'gradeTask');
    return jsonDecode(res.body);
  }

  /// (ROL DOCENTE) Obtiene todas las tareas ya calificadas por este docente.
  /// Consulta el endpoint de Agenda (donde viven las entregas reales)
  /// y devuelve la lista enriquecida con datos del estudiante.
  ///
  /// [teacherId] - ID de MongoDB del docente
  Future<List<dynamic>> getGradedTasksByTeacher(String teacherId) async {
    final uri = Uri.parse('$baseUrl/agenda/graded-by-teacher/$teacherId');
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    _checkStatus(res, 'getGradedTasksByTeacher');
    return jsonDecode(res.body);
  }

  /// (ROL DOCENTE) Actualiza la nota y/o comentario de una calificación existente en Agenda.
  /// Reutiliza el endpoint PUT /agenda/:id/grade para sobrescribir la calificación.
  ///
  /// [taskId]    - ID de MongoDB del item de agenda a recalificar
  /// [grade]     - Nueva nota (0–100)
  /// [teacherId] - ID del docente que realiza el cambio
  /// [comment]   - Nuevo comentario/retroalimentación (opcional)
  Future<Map<String, dynamic>> updateGrade(
    String taskId,
    int grade,
    String teacherId, {
    String comment = '',
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/agenda/$taskId/grade'),
      headers: _jsonHeaders,
      body: jsonEncode({
        'grade':          grade,
        'teacherComment': comment,
        'teacherId':      teacherId,
      }),
    );
    _checkStatus(res, 'updateGrade');
    return jsonDecode(res.body);
  }

  /// (ROL DOCENTE) Obtiene el PDF adjunto de una tarea para revisión.
  /// Devuelve { fileName, fileUrl (base64), uploadedAt }
  Future<Map<String, dynamic>> getTaskPdf(String taskId) async {
    final res = await http.get(Uri.parse('$baseUrl/tasks/$taskId/pdf'));
    _checkStatus(res, 'getTaskPdf');
    return jsonDecode(res.body);
  }

  /// Entrega un PDF como adjunto de un item de agenda tipo 'homework' (rol estudiante).
  /// Sube el archivo PDF usando multipart/form-data al endpoint de agenda.
  /// 
  /// [agendaItemId] - ID de MongoDB del item de agenda
  /// [pdfBytes]     - Bytes del archivo PDF leído con file_picker
  /// [fileName]     - Nombre original del archivo PDF
  /// [note]         - Nota/comentario opcional del estudiante
  /// 
  /// Devuelve: { message, item } con el item actualizado
  Future<Map<String, dynamic>> submitTaskPdf(
    String agendaItemId,
    List<int> pdfBytes,
    String fileName, {
    String? note,
    String? subject,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/agenda/$agendaItemId/submit-pdf'),
    );

    // Adjuntar el archivo PDF
    request.files.add(http.MultipartFile.fromBytes(
      'pdf',
      pdfBytes,
      filename:    fileName,
      contentType: MediaType('application', 'pdf'),
    ));

    // Nota opcional del estudiante
    if (note != null && note.trim().isNotEmpty) {
      request.fields['note'] = note.trim();
    }

    // Materia seleccionada (opcional)
    if (subject != null && subject.trim().isNotEmpty) {
      request.fields['subject'] = subject.trim();
    }

    try {
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        return jsonDecode(body);
      } else {
        final err = jsonDecode(body);
        throw Exception(err['error'] ?? 'Error al entregar PDF (${streamed.statusCode})');
      }
    } catch (e) {
      throw Exception('Error al entregar PDF: $e');
    }
  }

  // ─── Guardar FCM Token ──────────────────────────────────────
  /// Registra el token FCM del dispositivo en el backend.
  /// El backend usa este token para enviar notificaciones push
  /// a este dispositivo específico cuando ocurran eventos relevantes.
  ///
  /// [userId]   - ID del usuario dueño del dispositivo
  /// [token]    - Token FCM generado por Firebase en este dispositivo
  /// [platform] - Plataforma: 'android', 'ios', 'web'
  Future<void> saveFcmToken(String userId, String token, {String platform = 'android'}) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/notifications/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId':   userId,
          'fcmToken': token,
          'platform': platform,
        }),
      );
    } catch (e) {
      // No lanzar excepción: el token se enviará en el próximo login
      debugPrint('⚠️ No se pudo guardar FCM token: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  SECCIÓN 4: OCR (Escáner de Imágenes)
  // ═══════════════════════════════════════════════════════════

  /// Envía una imagen al servicio Python OCR para su procesamiento.
  /// 
  /// Usa multipart/form-data para enviar el archivo binario junto
  /// con los metadatos (userId, taskId) en el mismo formulario.
  /// El servicio Python guarda el resultado en MongoDB automáticamente.
  /// 
  /// [imageFile] - Archivo de imagen obtenido de la cámara/galería (XFile)
  /// [userId]    - ID del usuario que realiza el escaneo
  /// [taskId]    - ID de la tarea asociada (opcional)
  /// 
  /// Devuelve: { text, confidence, processing_time_ms, extracted_data,
  ///             status, saved_id (ID en MongoDB) }
  Future<Map<String, dynamic>> scanImage(
    XFile imageFile, {
    String userId = 'guest', // Por defecto 'guest' si no hay usuario logueado
    String? taskId,
  }) async {
    // MultipartRequest es la forma de enviar archivos binarios en HTTP
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$ocrUrl/extract-text/'),
    );

    // Leer los bytes del archivo de imagen y adjuntarlos al formulario
    final bytes = await imageFile.readAsBytes();
    request.files.add(http.MultipartFile.fromBytes(
      'file',             // Nombre del campo en el formulario (FastAPI lo espera como 'file')
      bytes,
      filename:    imageFile.name,                  // Nombre del archivo
      contentType: MediaType('image', 'jpeg'),      // Tipo MIME del archivo
    ));

    // Enviar también userId y taskId como campos de texto del formulario
    // El servicio Python los necesita para guardar el resultado en MongoDB
    request.fields['userId'] = userId;
    if (taskId != null) request.fields['taskId'] = taskId;

    try {
      // send() envía la petición de forma asíncrona
      final streamed = await request.send();
      // bytesToString() lee el cuerpo de la respuesta completo
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 200) {
        return jsonDecode(body); // Devolver el resultado del OCR
      } else {
        throw Exception('OCR Service Error (${streamed.statusCode}): $body');
      }
    } catch (e) {
      throw Exception('OCR Service Error: $e');
    }
  }

  /// Obtiene el historial de escaneos OCR de un usuario.
  /// El listado NO incluye la imagen Base64 (para no sobrecargar la red).
  /// Para ver la imagen, usar getOCRDetail().
  Future<List<dynamic>> getOCRHistory(String userId) async {
    final res = await http.get(Uri.parse('$baseUrl/ocr/$userId'));
    _checkStatus(res, 'getOCRHistory');
    return jsonDecode(res.body);
  }

  /// Obtiene un resultado OCR completo por su ID, incluyendo la imagen Base64.
  /// Útil para mostrar la vista previa de la imagen original escaneada.
  Future<Map<String, dynamic>> getOCRDetail(String ocrId) async {
    final res = await http.get(Uri.parse('$baseUrl/ocr/detail/$ocrId'));
    _checkStatus(res, 'getOCRDetail');
    return jsonDecode(res.body);
  }

  /// Elimina un resultado OCR específico del historial.
  Future<void> deleteOCRResult(String ocrId) async {
    final res = await http.delete(Uri.parse('$baseUrl/ocr/$ocrId'));
    _checkStatus(res, 'deleteOCRResult');
  }

  // ═══════════════════════════════════════════════════════════
  //  SECCIÓN 5: HISTORIAL DE ACTIVIDADES
  // ═══════════════════════════════════════════════════════════

  /// Obtiene el historial de actividades del usuario con paginación.
  /// 
  /// Parámetros opcionales:
  ///   [action]       - Filtrar por tipo: 'task_create', 'ocr_complete', etc.
  ///   [resourceType] - Filtrar por tipo de recurso: 'Task', 'OCRResult', etc.
  ///   [from]         - Solo eventos desde esta fecha
  ///   [to]           - Solo eventos hasta esta fecha
  ///   [page]         - Número de página (default: 1)
  ///   [limit]        - Registros por página (default: 20)
  /// 
  /// Devuelve: { total, page, pages, data: [...] }
  Future<Map<String, dynamic>> getHistory(
    String userId, {
    String?   action,
    String?   resourceType,
    DateTime? from,
    DateTime? to,
    int page  = 1,
    int limit = 20,
  }) async {
    // Construir parámetros de query para filtros y paginación
    final params = <String, String>{
      'page':  page.toString(),
      'limit': limit.toString(),
    };
    if (action       != null) params['action']       = action;
    if (resourceType != null) params['resourceType'] = resourceType;
    if (from         != null) params['from']         = from.toIso8601String();
    if (to           != null) params['to']           = to.toIso8601String();

    final uri = Uri.parse('$baseUrl/history/$userId')
        .replace(queryParameters: params);
    final res = await http.get(uri);
    _checkStatus(res, 'getHistory');
    return jsonDecode(res.body); // { total, page, pages, data }
  }

  // ═══════════════════════════════════════════════════════════
  //  SECCIÓN 6: UNIVERSO (Gamificación)
  // ═══════════════════════════════════════════════════════════

  /// Obtiene el universo del usuario. Si no tiene uno, el backend lo crea
  /// automáticamente con 4 planetas generados proceduralmente.
  /// Devuelve el documento completo del universo con todos sus planetas.
  Future<Map<String, dynamic>> getUniverse(String userId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/universe/$userId'));
      _checkStatus(res, 'getUniverse');
      return jsonDecode(res.body);
    } catch (e) {
      throw Exception('Error al obtener el universo: $e');
    }
  }

  /// Regenera (reinicia) el universo del usuario desde cero.
  /// El usuario pierde todos sus planetas y progreso anterior.
  /// Devuelve el nuevo universo generado.
  Future<Map<String, dynamic>> resetUniverse(String userId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/universe/reset/$userId'),
        headers: _jsonHeaders,
        // No necesita cuerpo, el userId va en la URL
      );
      _checkStatus(res, 'resetUniverse');
      return jsonDecode(res.body); // { success, message, universe }
    } catch (e) {
      throw Exception('Error al reiniciar el universo: $e');
    }
  }

  /// Coloniza/descubre un nuevo planeta en el universo del usuario.
  /// 
  /// [userId] - ID del usuario (requerido)
  /// [name]   - Nombre del planeta (opcional; si no se da, se genera aleatoriamente)
  /// [type]   - Tipo del planeta: 'terrestre', 'gaseoso', 'helado', 'volcánico', 'desértico'
  ///            (opcional; si no se da, se usa 'desértico' por defecto)
  /// 
  /// Devuelve: { success, planet, universe }
  Future<Map<String, dynamic>> addPlanet(String userId, {String? name, String? type}) async {
    try {
      final body = <String, dynamic>{'userId': userId};
      if (name != null) body['name'] = name;
      if (type != null) body['type'] = type;
      final res = await http.post(
        Uri.parse('$baseUrl/universe/planet'),
        headers: _jsonHeaders,
        body: jsonEncode(body),
      );
      _checkStatus(res, 'addPlanet');
      return jsonDecode(res.body);
    } catch (e) {
      throw Exception('Error al colonizar planeta: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  SECCIÓN 7: ADMINISTRACIÓN — Usuarios (admin panel)
  // ═══════════════════════════════════════════════════════════

  /// Obtiene estadísticas globales de usuarios.
  Future<Map<String, dynamic>> getAdminStats() async {
    final res = await http.get(Uri.parse('$baseUrl/admin/stats'));
    _checkStatus(res, 'getAdminStats');
    return jsonDecode(res.body);
  }

  /// Lista usuarios filtrados por rol y búsqueda opcional.
  Future<List<dynamic>> getUsers({String? role, String? search}) async {
    final params = <String, String>{};
    if (role != null)   params['role']   = role;
    if (search != null) params['search'] = search;
    final uri = Uri.parse('$baseUrl/admin/users').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    _checkStatus(res, 'getUsers');
    return jsonDecode(res.body);
  }

  /// Crea un nuevo usuario desde el panel admin.
  Future<Map<String, dynamic>> createUser(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin/users'),
      headers: _jsonHeaders,
      body: jsonEncode(data),
    );
    _checkStatus(res, 'createUser');
    return jsonDecode(res.body);
  }

  /// Actualiza datos de un usuario existente.
  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: _jsonHeaders,
      body: jsonEncode(data),
    );
    _checkStatus(res, 'updateUser');
    return jsonDecode(res.body);
  }

  /// Elimina un usuario por ID.
  Future<void> deleteUser(String userId) async {
    final res = await http.delete(Uri.parse('$baseUrl/admin/users/$userId'));
    _checkStatus(res, 'deleteUser');
  }

  // ═══════════════════════════════════════════════════════════
  //  SECCIÓN 8: MATERIAS
  // ═══════════════════════════════════════════════════════════

  Future<List<dynamic>> getMaterias({String? search, bool? activa}) async {
    final params = <String, String>{};
    if (search != null) params['search'] = search;
    if (activa != null) params['activa'] = activa.toString();
    final uri = Uri.parse('$baseUrl/materias').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    _checkStatus(res, 'getMaterias');
    return jsonDecode(res.body);
  }

  /// (ROL DOCENTE) Obtiene las materias asignadas formalmente a un docente.
  /// Consulta el modelo Materia con docenteId para obtener las asignaciones
  /// oficiales hechas desde el panel admin (no depende del campo User.materias).
  ///
  /// [teacherId] - ID de MongoDB del docente
  /// Devuelve lista de materias: [{ _id, nombre, codigo, area, semestre }]
  Future<List<dynamic>> getMateriasByDocente(String teacherId) async {
    final uri = Uri.parse('$baseUrl/materias').replace(queryParameters: {
      'docenteId': teacherId,
      'activa': 'true',
    });
    final res = await http.get(uri);
    _checkStatus(res, 'getMateriasByDocente');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createMateria(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/materias'), headers: _jsonHeaders, body: jsonEncode(data));
    _checkStatus(res, 'createMateria');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateMateria(String id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('$baseUrl/materias/$id'), headers: _jsonHeaders, body: jsonEncode(data));
    _checkStatus(res, 'updateMateria');
    return jsonDecode(res.body);
  }

  Future<void> deleteMateria(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/materias/$id'));
    _checkStatus(res, 'deleteMateria');
  }

  // ── Inscripciones ──────────────────────────────────────────

  /// (ROL DOCENTE) Obtiene los estudiantes inscritos en las materias del docente.
  /// El backend agrupa los resultados por materia y devuelve:
  ///   { materias: [...], porMateria: { nombreMateria: [...] }, estudiantes: [...], total: N }
  ///
  /// [docenteId] - ID de MongoDB del docente
  Future<Map<String, dynamic>> getEstudiantesDocente(String docenteId) async {
    final uri = Uri.parse('$baseUrl/inscripciones/docente/$docenteId');
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    _checkStatus(res, 'getEstudiantesDocente');
    return jsonDecode(res.body);
  }

  /// (ROL DOCENTE) Obtiene todos los estudiantes inscritos en una materia específica.
  /// [nombreMateria] - Nombre exacto de la materia (ej: "Matemáticas I")
  Future<List<dynamic>> getInscripcionesByMateria(String nombreMateria) async {
    final uri = Uri.parse('$baseUrl/inscripciones/materia/${Uri.encodeComponent(nombreMateria)}');
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    _checkStatus(res, 'getInscripcionesByMateria');
    return jsonDecode(res.body);
  }

  /// Lista todas las inscripciones con filtros opcionales (para el admin).
  /// [estado] - 'Pendiente', 'Aprobada', 'Rechazada'
  /// [asignatura] - Filtrar por nombre de materia
  Future<List<dynamic>> getInscripciones({String? estado, String? asignatura}) async {
    final params = <String, String>{};
    if (estado != null)     params['estado']     = estado;
    if (asignatura != null) params['asignatura'] = asignatura;
    final uri = Uri.parse('$baseUrl/inscripciones')
        .replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri).timeout(const Duration(seconds: 30));
    _checkStatus(res, 'getInscripciones');
    return jsonDecode(res.body);
  }

  /// Crea una nueva inscripción desde el panel admin.
  Future<Map<String, dynamic>> createInscripcion(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/inscripciones'),
        headers: _jsonHeaders, body: jsonEncode(data));
    _checkStatus(res, 'createInscripcion');
    return jsonDecode(res.body);
  }

  /// Aprueba o rechaza una inscripción.
  Future<Map<String, dynamic>> updateInscripcion(String id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('$baseUrl/inscripciones/$id'),
        headers: _jsonHeaders, body: jsonEncode(data));
    _checkStatus(res, 'updateInscripcion');
    return jsonDecode(res.body);
  }

  // ═══════════════════════════════════════════════════════════
  //  SECCIÓN 9: ACTIVIDADES ACADÉMICAS
  // ═══════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getActividadesStats() async {
    final res = await http.get(Uri.parse('$baseUrl/actividades/stats'));
    _checkStatus(res, 'getActividadesStats');
    return jsonDecode(res.body);
  }

  Future<List<dynamic>> getActividades({String? tipo, String? estado, String? search}) async {
    final params = <String, String>{};
    if (tipo   != null) params['tipo']   = tipo;
    if (estado != null) params['estado'] = estado;
    if (search != null) params['search'] = search;
    final uri = Uri.parse('$baseUrl/actividades').replace(queryParameters: params.isEmpty ? null : params);
    final res = await http.get(uri);
    _checkStatus(res, 'getActividades');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> createActividad(Map<String, dynamic> data) async {
    final res = await http.post(Uri.parse('$baseUrl/actividades'), headers: _jsonHeaders, body: jsonEncode(data));
    _checkStatus(res, 'createActividad');
    return jsonDecode(res.body);
  }

  Future<Map<String, dynamic>> updateActividad(String id, Map<String, dynamic> data) async {
    final res = await http.put(Uri.parse('$baseUrl/actividades/$id'), headers: _jsonHeaders, body: jsonEncode(data));
    _checkStatus(res, 'updateActividad');
    return jsonDecode(res.body);
  }

  Future<void> deleteActividad(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl/actividades/$id'));
    _checkStatus(res, 'deleteActividad');
  }
}
