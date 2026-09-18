// ============================================================
// screens/teacher_dashboard_screen.dart — Panel del Docente
// ============================================================
// Pantalla exclusiva para el rol 'teacher'. Muestra todas las
// tareas entregadas por estudiantes que están pendientes de
// calificación (status: 'in_progress').
//
// Funcionalidades:
//   - Lista de tareas entregadas con datos del estudiante
//   - Pull-to-refresh para actualizar la lista
//   - Tarjetas con animación 3D de entrada
//   - Acceso a la pantalla de calificación
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  List<dynamic> _tasks = [];
  bool _isLoading = true;
  bool _isLoadingMaterias = false; // Estado de carga de materias desde API
  String? _teacherId;
  String? _teacherName;
  String? _teacherMaterias;        // Materias asignadas al docente (cache String CSV)
  List<String> _assignedSubjects = []; // Lista de materias cargadas desde API
  bool _isInit = false;

  // Filtros
  String? _selectedSubject;        // null = "Todas"
  List<String> get _subjects => ['Todas', ..._assignedSubjects];

  late AnimationController _headerController;
  late AnimationController _listController;
  late AnimationController _shimmerController;
  late Animation<double> _headerOpacity;
  late Animation<Offset>  _headerSlide;
  late Animation<double>  _shimmer;

  @override
  void initState() {
    super.initState();

    _headerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );
    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _listController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700),
    );

    _shimmerController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmer = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _teacherId      = args?['_id']   ?? '';
      _teacherName    = args?['name']  ?? 'Docente';
      _teacherMaterias = args?['materias'] as String?; // Cache inicial del login

      // ── Carga inicial desde el String del login (si existe) ──────
      // Esto permite mostrar algo inmediatamente mientras cargamos de la API
      if (_teacherMaterias != null && _teacherMaterias!.trim().isNotEmpty) {
        _assignedSubjects = _teacherMaterias!
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }

      _headerController.forward();
      // Cargar materias desde la API (fuente de verdad) y luego las tareas
      _loadMateriasAndFetchTasks();
      // ── Notificación de fecha límite de calificaciones ────────────
      // Se muestra en la barra de notificaciones al ingresar al rol docente
      _mostrarNotificacionCalificaciones();
      _isInit = true;
    }
  }

  /// Carga las materias asignadas al docente desde la API (modelo Materia),
  /// luego actualiza la lista y carga las tareas entregadas.
  /// Usa dos fuentes de verdad combinadas:
  ///   1. API → modelo Materia (docenteId) — asignación formal del admin
  ///   2. User.materias del login — fallback / asignación manual
  Future<void> _loadMateriasAndFetchTasks() async {
    if (_teacherId == null || _teacherId!.isEmpty) {
      _fetchTasks();
      return;
    }
    setState(() => _isLoadingMaterias = true);
    try {
      // Cargar materias desde el modelo Materia del backend
      final materias = await _apiService.getMateriasByDocente(_teacherId!);
      if (!mounted) return;

      // Construir lista de nombres desde la API
      final fromApi = materias
          .map<String>((m) => (m['nombre'] as String? ?? '').trim())
          .where((s) => s.isNotEmpty)
          .toList();

      // Combinar con las del login (sin duplicados)
      final fromLogin = (_teacherMaterias != null && _teacherMaterias!.trim().isNotEmpty)
          ? _teacherMaterias!.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : <String>[];

      final combined = {...fromApi, ...fromLogin}.toList();

      setState(() {
        _assignedSubjects = combined;
        _isLoadingMaterias = false;
      });

      if (combined.isNotEmpty) {
        debugPrint('📚 Materias del docente cargadas: $combined');
      } else {
        debugPrint('⚠️ El docente no tiene materias asignadas en ningún sistema');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingMaterias = false);
      debugPrint('⚠️ Error al cargar materias del docente: $e');
      // Continuar con las materias del login si las hay
    }
    _fetchTasks();
  }

  /// Muestra una notificación local en la barra de estado al ingresar al
  /// panel docente, recordando la fecha límite de entrega de calificaciones.
  Future<void> _mostrarNotificacionCalificaciones() async {
    await NotificationService().showCalificacionesDeadline(
      teacherName: _teacherName ?? 'Docente',
    );
  }

  @override
  void dispose() {
    _headerController.dispose();
    _listController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _fetchTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final subject = (_selectedSubject == null || _selectedSubject == 'Todas')
          ? null
          : _selectedSubject;
      // Si hay filtro de materia específico, NO enviamos teacherId (ya filtrado en UI)
      // Si es "Todas", enviamos teacherId para que el backend filtre por sus materias
      final tasks = await _apiService.getSubmittedAgendaTasks(
        subject:   subject,
        teacherId: (_teacherId != null && _teacherId!.isNotEmpty) ? _teacherId : null,
      );
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
      _listController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cargar tareas: $e'),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: RefreshIndicator(
        onRefresh: _fetchTasks,
        color: const Color(0xFF1A237E),
        child: Column(
          children: [
            _buildHeader(),
            _buildFilterBar(),
            const SizedBox(height: 4),
            _buildStatsRow(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, _) => SlideTransition(
        position: _headerSlide,
        child: FadeTransition(
          opacity: _headerOpacity,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D1B4E), Color(0xFF1A237E), Color(0xFF283593)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
                child: Row(
                  children: [
                    // Botón volver
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white.withOpacity(0.12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2), width: 1,
                          ),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Icono docente
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6F00), Color(0xFFFFC107)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withOpacity(0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.school_rounded,
                            color: Color(0xFF0D1B4E), size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panel Docente',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _teacherName ?? 'Docente',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Botón de historial de calificaciones
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/teacher-grade-history',
                        arguments: {
                          '_id':  _teacherId,
                          'name': _teacherName,
                        },
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF43A047).withOpacity(0.18),
                          border: Border.all(
                            color: const Color(0xFF43A047).withOpacity(0.4), width: 1,
                          ),
                        ),
                        child: const Icon(Icons.history_edu_rounded,
                            color: Color(0xFF81C784), size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ── Botón Tareas por Materia ───────────────────
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/teacher-submitted-tasks',
                        arguments: {
                          '_id':  _teacherId,
                          'name': _teacherName,
                        },
                      ).then((_) => _fetchTasks()),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFFFFC107).withOpacity(0.18),
                          border: Border.all(
                            color: const Color(0xFFFFC107).withOpacity(0.5), width: 1,
                          ),
                        ),
                        child: const Icon(Icons.assignment_turned_in_rounded,
                            color: Color(0xFFFFC107), size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // ── Botón Mis Estudiantes ──────────────────
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/teacher-students',
                        arguments: {
                          '_id':  _teacherId,
                          'name': _teacherName,
                        },
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: const Color(0xFF26C6DA).withOpacity(0.18),
                          border: Border.all(
                            color: const Color(0xFF26C6DA).withOpacity(0.4), width: 1,
                          ),
                        ),
                        child: const Icon(Icons.groups_rounded,
                            color: Color(0xFF80DEEA), size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge de tareas pendientes
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFFE53935).withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pending_actions_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${_tasks.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Barra de filtro por materia ─────────────────────────────
  // Muestra solo las materias asignadas al docente (+ "Todas")
  // Si el docente no tiene materias asignadas, muestra las predeterminadas.

  Widget _buildFilterBar() {
    // Si no hay materias asignadas al docente, mostrar mensaje informativo
    final subjects = _subjects.isEmpty
        ? ['Todas']
        : _subjects;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de materias asignadas
          if (_assignedSubjects.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.assignment_ind_rounded,
                      size: 14, color: Color(0xFF1A237E)),
                  const SizedBox(width: 4),
                  Text(
                    'Mis materias: ${_assignedSubjects.join(', ')}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subjects.map((subject) {
                final isSelected = (_selectedSubject == subject) ||
                    (_selectedSubject == null && subject == 'Todas');
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedSubject = subject == 'Todas' ? null : subject);
                    _fetchTasks();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFF1A237E), Color(0xFF283593)],
                            )
                          : null,
                      color: isSelected ? null : const Color(0xFFF0F4FF),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF1A237E).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    child: Text(
                      subject,
                      style: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF1A237E),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Fila de estadísticas ────────────────────────────────────

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFC107), Color(0xFF1A237E)],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isLoading
                ? 'Cargando tareas...'
                : '${_tasks.length} tarea${_tasks.length != 1 ? 's' : ''} por revisar',
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Cuerpo principal ────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_tasks.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment(_shimmer.value - 1, 0),
              end: Alignment(_shimmer.value, 0),
              colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    // Mostrar estado diferenciado:
    // Si no tiene materias asignadas → alerta de configuración
    // Si tiene materias pero sin tareas → estado de éxito
    final bool noMateriasAsignadas = _assignedSubjects.isEmpty && !_isLoadingMaterias;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Ícono central ──────────────────────────────────────
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: noMateriasAsignadas
                      ? [const Color(0xFFFF6F00).withOpacity(0.15), const Color(0xFFFFC107).withOpacity(0.08)]
                      : [const Color(0xFF43A047).withOpacity(0.12), const Color(0xFF2E7D32).withOpacity(0.06)],
                ),
              ),
              child: Center(
                child: Icon(
                  noMateriasAsignadas
                      ? Icons.assignment_ind_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 54,
                  color: noMateriasAsignadas
                      ? const Color(0xFFFF8F00)
                      : const Color(0xFF43A047),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Título ──────────────────────────────────────────────
            Text(
              noMateriasAsignadas ? 'Sin materias asignadas' : '¡Todo revisado!',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: noMateriasAsignadas
                    ? const Color(0xFFE65100)
                    : const Color(0xFF1A237E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // ── Subtítulo ───────────────────────────────────────────
            Text(
              noMateriasAsignadas
                  ? 'El administrador aún no te ha asignado ninguna materia.\nCuando se asignen, verás aquí las tareas entregadas por tus estudiantes.'
                  : 'No hay tareas pendientes de calificación en tus materias.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),

            // ── Banner informativo (solo si no hay materias) ────────
            if (noMateriasAsignadas) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFC107).withOpacity(0.5),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFC107).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.info_outline_rounded,
                              color: Color(0xFFFF8F00), size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Paso a seguir',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Pídele al administrador del colegio que abra el panel web, vaya a "Materias" y te asigne las materias correspondientes con tu cuenta de docente.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF795548),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Botón actualizar ────────────────────────────────────
            ElevatedButton.icon(
              onPressed: _loadMateriasAndFetchTasks,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(noMateriasAsignadas ? 'Verificar asignación' : 'Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: noMateriasAsignadas
                    ? const Color(0xFFFF8F00)
                    : const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return AnimatedBuilder(
      animation: _listController,
      builder: (_, __) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        itemCount: _tasks.length,
        itemBuilder: (_, i) {
          final progress = (_listController.value - i * 0.1).clamp(0.0, 1.0);
          final curved  = Curves.easeOutCubic.transform(progress);
          final flipX   = (1 - curved) * -0.4;
          return Opacity(
            opacity: curved,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(flipX)
                ..translate(0.0, (1 - curved) * 40.0),
              child: _buildTaskCard(_tasks[i]),
            ),
          );
        },
      ),
    );
  }

  // ── Tarjeta de tarea ────────────────────────────────────────

  final Map<int, bool> _cardPressed = {};

  Widget _buildTaskCard(dynamic task) {
    final student    = task['userId'];
    final studentName = (student is Map) ? (student['name'] ?? 'Estudiante') : 'Estudiante';
    final studentGrade = (student is Map) ? (student['grade'] ?? '') : '';
    final subject    = task['subject'] ?? 'Sin materia';
    final title      = task['title']   ?? 'Sin título';
    final updatedAt  = task['updated_at'] != null
        ? DateTime.tryParse(task['updated_at'])
        : null;
    final index = _tasks.indexOf(task);
    final isPressed = _cardPressed[index] ?? false;

    // Color por materia
    final color = _subjectColor(subject);

    return GestureDetector(
      onTapDown: (_) => setState(() => _cardPressed[index] = true),
      onTapUp: (_) => setState(() => _cardPressed[index] = false),
      onTapCancel: () => setState(() => _cardPressed[index] = false),
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          '/teacher-grade',
          arguments: {
            'task':       task,
            'teacherId':  _teacherId,
            'teacherName': _teacherName,
          },
        );
        if (result == true) _fetchTasks();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        transformAlignment: Alignment.center,
        transform: isPressed
            ? (Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..scale(0.97)
              ..rotateX(0.04))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isPressed
              ? [BoxShadow(color: color.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))]
              : [
                  BoxShadow(color: color.withOpacity(0.2), blurRadius: 24, offset: const Offset(0, 8)),
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3)),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Fila superior: icono + materia + badge PDF
              Row(
                children: [
                  // Ícono de materia
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.6)],
                      ),
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.3), blurRadius: 10),
                      ],
                    ),
                    child: Center(
                      child: Icon(_subjectIcon(subject), color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subject,
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF0D1B4E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Badge "PDF adjunto"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE53935).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded,
                            color: Color(0xFFE53935), size: 13),
                        SizedBox(width: 4),
                        Text(
                          'PDF',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 12),

              // Fila inferior: estudiante + fecha + flecha
              Row(
                children: [
                  // Avatar estudiante
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF1A237E).withOpacity(0.1),
                    child: Text(
                      studentName.isNotEmpty ? studentName[0].toUpperCase() : 'E',
                      style: const TextStyle(
                        color: Color(0xFF1A237E),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF0D1B4E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (studentGrade.isNotEmpty)
                          Text(
                            studentGrade,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (updatedAt != null) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.upload_rounded,
                                size: 11, color: Color(0xFF43A047)),
                            const SizedBox(width: 2),
                            Text(
                              'Entregado',
                              style: TextStyle(
                                fontSize: 10,
                                color: const Color(0xFF43A047),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          DateFormat('dd MMM yyyy', 'es_ES').format(updatedAt.toLocal()),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E),
                          ),
                        ),
                        Text(
                          DateFormat('HH:mm', 'es_ES').format(updatedAt.toLocal()),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF1A237E).withOpacity(0.07),
                    ),
                    child: const Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF1A237E), size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  Color _subjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('mat'))   return const Color(0xFF1565C0);
    if (s.contains('leng'))  return const Color(0xFF6A1B9A);
    if (s.contains('cien'))  return const Color(0xFF2E7D32);
    if (s.contains('hist'))  return const Color(0xFFBF360C);
    if (s.contains('ingl'))  return const Color(0xFF00838F);
    if (s.contains('fís'))   return const Color(0xFFE65100);
    return const Color(0xFF37474F);
  }

  IconData _subjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('mat'))   return Icons.calculate_rounded;
    if (s.contains('leng'))  return Icons.menu_book_rounded;
    if (s.contains('cien'))  return Icons.science_rounded;
    if (s.contains('hist'))  return Icons.account_balance_rounded;
    if (s.contains('ingl'))  return Icons.language_rounded;
    if (s.contains('fís'))   return Icons.sports_soccer_rounded;
    return Icons.book_rounded;
  }
}
