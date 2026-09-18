// ============================================================
// main.dart — Punto de entrada de la aplicación Flutter
// ============================================================
// Este archivo inicializa la app y configura el sistema de rutas
// con animaciones de transición personalizadas entre pantallas.
// También configura el tema visual global y la localización en español.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import kIsWeb
import 'package:firebase_core/firebase_core.dart';    // Firebase Core

// Importar todas las pantallas de la aplicación
import 'screens/splash_screen.dart';    // Pantalla de carga inicial (logo + verificación de sesión)
import 'screens/login_screen.dart';     // Pantalla de inicio de sesión
import 'screens/register_screen.dart';  // Pantalla de registro de nuevo usuario
import 'screens/home_screen.dart';      // Pantalla principal con tareas y agenda
import 'screens/camera_screen.dart';    // Pantalla del escáner OCR con la cámara
import 'screens/universe_screen.dart';  // Pantalla del universo (gamificación)
import 'screens/submit_task_screen.dart';        // Pantalla de entrega de tarea PDF (estudiante)
import 'screens/edit_agenda_screen.dart';   // Pantalla de edición de evento/tarea
import 'screens/teacher_dashboard_screen.dart'; // Panel del docente: revisar tareas entregadas
import 'screens/teacher_grade_task_screen.dart'; // Pantalla de calificación de tarea (docente)
import 'screens/teacher_grade_history_screen.dart'; // Historial de calificaciones del docente
import 'screens/teacher_students_screen.dart';       // Mis Estudiantes (docente): inscritos en sus materias
import 'screens/teacher_submitted_tasks_screen.dart'; // Tareas entregadas agrupadas por materia (docente)
import 'screens/admin_dashboard_screen.dart';    // Panel administrativo
import 'services/notification_service.dart'; // Servicio FCM de notificaciones push

// Localización: permite mostrar fechas, números y textos en español
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Clave global del navegador — necesaria para la navegación desde notificaciones
/// cuando la app está en background/terminated.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Punto de entrada de la aplicación Flutter.
/// Se ejecuta cuando la app arranca.
void main() async {
  // Asegurar que los bindings de Flutter estén inicializados antes de
  // llamar a código nativo (como initializeDateFormatting).
  // Necesario cuando se usa async en main().
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase (necesario antes de usar cualquier servicio Firebase)
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "dummy-api-key-german-busch-web",
          appId: "dummy-app-id-web",
          messagingSenderId: "dummy-sender-id",
          projectId: "dummy-project-id",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
  } catch (e) {
    debugPrint('⚠️ Error initializing Firebase: $e');
  }

  // Inicializar el servicio de notificaciones push (FCM)
  // Se envuelve en try-catch para evitar el assertion '_dependents.isEmpty'
  // que ocurre cuando Firebase intenta acceder al árbol de widgets antes de que esté listo.
  try {
    await NotificationService().initialize(
      navKey: navigatorKey,
    );
  } catch (e) {
    debugPrint('⚠️ NotificationService init error (no crítico): $e');
  }

  // Inicializar los datos de formato de fecha para el idioma español.
  // Esto permite mostrar fechas como "ℙunes, 22 de mayo de 2025".
  await initializeDateFormatting('es_ES', null);

  // Arrancar la aplicación con el widget raíz ColegioApp
  runApp(const ColegioApp());
}

/// Widget raíz de la aplicación.
/// StatelessWidget porque la configuración global no cambia en tiempo de ejecución.
class ColegioApp extends StatelessWidget {
  const ColegioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Colegio Germán Busch "A"',   // Nombre mostrado en el administrador de tareas
      debugShowCheckedModeBanner: false,    // Ocultar el banner rojo "DEBUG" en la esquina
      navigatorKey: navigatorKey,           // Clave global para navegación desde notificaciones

      // ── Tema visual global ─────────────────────────────────
      // Define los colores y estilos que se aplican a toda la app.
      // Material 3 es la versión más moderna del sistema de diseño de Google.
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E), // Azul marino oscuro (color principal)
          primary:   const Color(0xFF1A237E),
          secondary: const Color(0xFFFFC107), // Amarillo ámbar (color secundario/acento)
        ),
        fontFamily: 'Roboto', // Fuente tipográfica de toda la app

        // Estilos de texto globales
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A237E)),
          titleLarge:   TextStyle(fontWeight: FontWeight.w600),
        ),

        // Estilo global de todos los botones elevados (ElevatedButton)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0, // Sin sombra (diseño plano/moderno)
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14), // Bordes redondeados
            ),
            padding: const EdgeInsets.symmetric(vertical: 16), // Altura del botón
          ),
        ),

        // Estilo global de todos los campos de texto (TextField)
        inputDecorationTheme: InputDecorationTheme(
          filled:    true,               // Fondo con color de relleno
          fillColor: Colors.grey[100],   // Color de relleno gris muy claro

          // Borde por defecto (no enfocado): sin línea visible
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),

          // Borde cuando el campo está enfocado: línea azul de 2px
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
          ),
        ),
      ),

      // ── Localización en español ────────────────────────────
      // Estos delegates permiten que widgets de Material (como DatePicker)
      // muestren sus textos en español (ej: "Aceptar", "Cancelar", nombres de meses).
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Idiomas soportados: español de Bolivia y español genérico
      supportedLocales: const [
        Locale('es', 'BO'), // Español Bolivia (preferido)
        Locale('es', ''),   // Español genérico (fallback)
      ],

      // ── Sistema de rutas y navegación ─────────────────────
      initialRoute: '/login',

      // onGenerateRoute permite personalizar las transiciones entre pantallas.
      // Se ejecuta cada vez que se navega con Navigator.pushNamed().
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/splash':
            // Fade: transición de fundido suave (entrada a la app)
            return _buildPageRoute(const SplashScreen(), settings, PageTransitionType.fade);
          case '/login':
            return _buildPageRoute(const LoginScreen(), settings, PageTransitionType.fade);
          case '/register':
            // SlideUp: deslizamiento hacia arriba (acción modal)
            return _buildPageRoute(const RegisterScreen(), settings, PageTransitionType.slideUp);
          case '/home':
            return _buildPageRoute(const HomeScreen(), settings, PageTransitionType.fade);
          case '/camera':
            // SlideUp: la cámara aparece como modal desde abajo
            return _buildPageRoute(const CameraScreen(), settings, PageTransitionType.slideUp);
          case '/universe':
            return _buildPageRoute(const UniverseScreen(), settings, PageTransitionType.fade);
          case '/edit-agenda':
            // SlideUp: la pantalla de edición sube como modal
            return _buildPageRoute(const EditAgendaScreen(), settings, PageTransitionType.slideUp);
          case '/submit-task':
            // SlideUp: la pantalla de entrega sube como modal
            return _buildPageRoute(const SubmitTaskScreen(), settings, PageTransitionType.slideUp);
          case '/teacher-dashboard':
            // SlideUp: el panel docente sube desde abajo
            return _buildPageRoute(const TeacherDashboardScreen(), settings, PageTransitionType.slideUp);
          case '/teacher-grade':
            // SlideUp: la pantalla de calificación sube como modal
            return _buildPageRoute(const TeacherGradeTaskScreen(), settings, PageTransitionType.slideUp);
          case '/teacher-grade-history':
            // SlideUp: el historial de calificaciones sube como modal
            return _buildPageRoute(const TeacherGradeHistoryScreen(), settings, PageTransitionType.slideUp);
          case '/teacher-students':
            // SlideUp: la pantalla de mis estudiantes sube como modal
            return _buildPageRoute(const TeacherStudentsScreen(), settings, PageTransitionType.slideUp);
          case '/teacher-submitted-tasks':
            // SlideUp: tareas entregadas por materia
            return _buildPageRoute(const TeacherSubmittedTasksScreen(), settings, PageTransitionType.slideUp);
          case '/admin-dashboard':
            return _buildPageRoute(const AdminDashboardScreen(), settings, PageTransitionType.fade);
          default:
            // Si la ruta no existe, redirigir al login por seguridad
            return _buildPageRoute(const LoginScreen(), settings, PageTransitionType.fade);
        }
      },
    );
  }

  /// Crea una ruta de página con animación de transición personalizada.
  ///
  /// [page]     Widget de la pantalla destino
  /// [settings] Configuración de la ruta (nombre, argumentos)
  /// [type]     Tipo de animación: fade o slideUp
  PageRoute _buildPageRoute(Widget page, RouteSettings settings, PageTransitionType type) {
    switch (type) {
      case PageTransitionType.slideUp:
        // Transición de deslizamiento hacia arriba combinada con fade
        // La pantalla aparece desde 8% abajo de su posición final
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, anim, __) => page,
          transitionDuration: const Duration(milliseconds: 400), // Duración: 400ms
          transitionsBuilder: (_, anim, __, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08), // Empieza 8% abajo de la posición final
                end: Offset.zero,             // Termina en posición normal (0, 0)
              ).animate(CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic, // Curva suave: rápida al inicio, lenta al final
              )),
              child: FadeTransition(opacity: anim, child: child), // También hace fade
            );
          },
        );

      case PageTransitionType.fade:
        // Transición de fundido simple (fade in)
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (_, anim, __) => page,
          transitionDuration: const Duration(milliseconds: 350), // Duración: 350ms
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
              child: child,
            );
          },
        );
    }
  }
}

/// Tipos de animación de transición disponibles entre pantallas.
enum PageTransitionType {
  fade,    // Fundido: la pantalla aparece gradualmente
  slideUp  // Deslizamiento: la pantalla sube desde abajo
}
