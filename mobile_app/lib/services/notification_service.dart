// ============================================================
// services/notification_service.dart — Firebase Cloud Messaging
// ============================================================
// Maneja el ciclo completo de notificaciones push en la app:
//   1. Inicialización de Firebase + FCM
//   2. Solicitud de permisos al usuario
//   3. Obtención del FCM Token del dispositivo
//   4. Notificaciones en FOREGROUND (app abierta) → notificación local
//   5. Notificaciones en BACKGROUND → se muestran automáticamente
//   6. Tap en notificación → navegación a la pantalla correcta
// ============================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import kIsWeb
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Handler de mensajes en background/terminated ────────────
// DEBE ser una función de nivel superior (no un método de clase)
// porque se ejecuta en un isolate separado de Flutter.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No necesitamos hacer nada aquí: FCM muestra la notificación automáticamente
  // cuando la app está en background o cerrada y el mensaje tiene `notification`.
  debugPrint('📬 FCM Background: ${message.notification?.title}');
}

class NotificationService {
  // ── Singleton ────────────────────────────────────────────────
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ── Instancias de Firebase y notificaciones locales ──────────
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ── Clave global de navegación (se inyecta desde main.dart) ──
  GlobalKey<NavigatorState>? navigatorKey;

  // ── Canales de notificaciones Android ─────────────────────────
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tareas_channel',           // ID (mismo que en AndroidManifest)
    'Tareas y Recordatorios',   // Nombre visible para el usuario
    description: 'Notificaciones del Colegio Germán Busch',
    importance: Importance.high,
    playSound: true,
  );

  static const AndroidNotificationChannel _calificacionesChannel = AndroidNotificationChannel(
    'calificaciones_channel',
    'Fechas Límite de Calificaciones',
    description: 'Recordatorios de entrega de calificaciones para docentes',
    importance: Importance.max,
    playSound: true,
  );

  // ── Token FCM del dispositivo ────────────────────────────────
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Callbacks que puede registrar la app
  Function(String token)? onTokenRefresh;
  Function(Map<String, dynamic> data)? onNotificationTap;

  // ============================================================
  //  INICIALIZACIÓN PRINCIPAL
  // ============================================================

  /// Inicializa el servicio completo de notificaciones.
  /// Llamar una sola vez en main.dart después de Firebase.initializeApp().
  Future<void> initialize({
    GlobalKey<NavigatorState>? navKey,
    Function(String token)? onToken,
    Function(Map<String, dynamic> data)? onTap,
  }) async {
    navigatorKey = navKey;
    onTokenRefresh = onToken;
    onNotificationTap = onTap;

    if (kIsWeb) {
      debugPrint('ℹ️ FCM desactivado en Web');
      return;
    }

    try {
      // 1. Registrar handler de background
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 2. Crear canales de notificaciones Android
      await _createNotificationChannel();

      // 3. Inicializar flutter_local_notifications (para foreground)
      await _initLocalNotifications();

      // 4. Solicitar permisos al usuario
      await _requestPermissions();

      // 5. Obtener el token FCM del dispositivo
      await _fetchToken();

      // 6. Configurar handlers de mensajes
      _setupMessageHandlers();

      debugPrint('✅ NotificationService inicializado. Token: $_fcmToken');
    } catch (e) {
      debugPrint('⚠️ NotificationService: error no crítico al inicializar FCM: $e');
      // La app funciona normalmente sin notificaciones push
    }
  }

  // ── Crear canales Android ────────────────────────────────────
  Future<void> _createNotificationChannel() async {
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.createNotificationChannel(_calificacionesChannel);
  }

  // ── Inicializar notificaciones locales ───────────────────────
  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );
  }

  // ── Solicitar permisos ───────────────────────────────────────
  Future<void> _requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert:         true,
      announcement:  false,
      badge:         true,
      carPlay:       false,
      criticalAlert: false,
      provisional:   false,
      sound:         true,
    );
    debugPrint('🔔 Permisos FCM: ${settings.authorizationStatus}');

    // Solicitar permiso de notificaciones locales en Android 13+
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  // ── Obtener token FCM ────────────────────────────────────────
  Future<void> _fetchToken() async {
    try {
      _fcmToken = await _fcm.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');

      // Escuchar renovaciones automáticas del token
      _fcm.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('🔄 FCM Token renovado: $newToken');
        onTokenRefresh?.call(newToken);
      });
    } catch (e) {
      debugPrint('❌ Error obteniendo FCM token: $e');
    }
  }

  // ============================================================
  //  HANDLERS DE MENSAJES
  // ============================================================

  void _setupMessageHandlers() {
    // ── FOREGROUND: app abierta ─────────────────────────────────
    // FCM no muestra notificación automáticamente → la mostramos nosotros
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 FCM Foreground: ${message.notification?.title}');
      _showLocalNotification(message);
    });

    // ── BACKGROUND TAP: usuario tocó la notificación ────────────
    // App estaba en background y el usuario la abrió desde la notif
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('👆 FCM tap desde background: ${message.data}');
      _handleNotificationTap(message.data);
    });

    // ── TERMINATED TAP: app estaba cerrada ──────────────────────
    // Verificar si la app fue abierta desde una notificación
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      debugPrint('🚀 App abierta desde notificación: ${initial.data}');
      // Pequeño delay para que la navegación esté lista
      await Future.delayed(const Duration(milliseconds: 500));
      _handleNotificationTap(initial.data);
    }
  }

  // ── Mostrar notificación local (foreground) ──────────────────
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: const Color(0xFFFFC107),
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        summaryText: 'Colegio Germán Busch',
      ),
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data), // Datos para el tap
    );
  }

  // ── Tap en notificación local (foreground) ───────────────────
  void _onLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!) as Map<String, dynamic>;
        _handleNotificationTap(data);
      } catch (_) {}
    }
  }

  // ── Navegar según el tipo de notificación ───────────────────
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final nav = navigatorKey?.currentState;
    if (nav == null) return;

    switch (type) {
      case 'homework':
      case 'task':
        // Navegar a home (la agenda está ahí)
        nav.pushNamedAndRemoveUntil('/home', (r) => false,
            arguments: {'_id': data['userId'], 'name': data['userName'] ?? ''});
        break;
      case 'submit_confirm':
        // Confirmación de entrega → home
        nav.pushNamedAndRemoveUntil('/home', (r) => false,
            arguments: {'_id': data['userId'], 'name': data['userName'] ?? ''});
        break;
      default:
        // Por defecto, volver a home
        nav.pushNamedAndRemoveUntil('/home', (r) => false,
            arguments: {'_id': data['userId'], 'name': data['userName'] ?? ''});
    }
    onNotificationTap?.call(data);
  }

  // ============================================================
  //  UTILIDADES PÚBLICAS
  // ============================================================

  /// Enviar una notificación local de prueba (sin necesitar servidor)
  Future<void> sendTestNotification({
    String title = '🎓 Colegio Germán Busch',
    String body  = 'Las notificaciones push están funcionando ✅',
  }) async {
    await _showLocalNotification(RemoteMessage(
      notification: RemoteNotification(title: title, body: body),
      data: {'type': 'test'},
    ));
  }

  /// Muestra notificación de fecha límite de calificaciones al ingresar
  /// como docente. Aparece directamente en la barra de notificaciones.
  Future<void> showCalificacionesDeadline({String teacherName = 'Docente'}) async {
    const androidDetails = AndroidNotificationDetails(
      'calificaciones_channel',
      'Fechas Límite de Calificaciones',
      channelDescription: 'Recordatorios de entrega de calificaciones',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFFC107),
      styleInformation: BigTextStyleInformation(
        'Señor docente, la entrega de calificaciones es una fecha límite para subir.\n\n'
        'Por favor, no olvide registrar las notas de sus estudiantes antes de que venza el plazo establecido.',
        contentTitle: '⚠️ Fecha Límite de Calificaciones',
        summaryText: 'Colegio Germán Busch',
      ),
      ticker: 'Recordatorio de calificaciones',
    );

    await _localNotifications.show(
      9001, // ID fijo para esta notificación
      '⚠️ Recordatorio de Calificaciones',
      'Señor docente, la entrega de calificaciones es una fecha límite para subir.',
      const NotificationDetails(android: androidDetails),
    );
    debugPrint('🔔 Notificación de calificaciones mostrada para: $teacherName');
  }


  /// Suscribir a un topic (para notificaciones broadcast)
  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    await _fcm.subscribeToTopic(topic);
    debugPrint('📡 Suscrito al topic: $topic');
  }

  /// Desuscribir de un topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    await _fcm.unsubscribeFromTopic(topic);
  }
}
