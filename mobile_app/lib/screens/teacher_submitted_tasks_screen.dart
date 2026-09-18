// ============================================================
// screens/teacher_submitted_tasks_screen.dart
// Panel del Docente — Tareas Entregadas por Materia
// ============================================================
// Muestra todas las tareas que los estudiantes han entregado,
// organizadas por materia con pestañas dinámicas.
// ============================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class TeacherSubmittedTasksScreen extends StatefulWidget {
  const TeacherSubmittedTasksScreen({super.key});

  @override
  State<TeacherSubmittedTasksScreen> createState() =>
      _TeacherSubmittedTasksScreenState();
}

class _TeacherSubmittedTasksScreenState
    extends State<TeacherSubmittedTasksScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();

  // Datos del docente recibidos por argumentos de ruta
  String? _teacherId;
  String? _teacherName;

  // Todas las tareas entregadas
  List<dynamic> _allTasks = [];
  bool _isLoading = true;
  bool _isInit = false;

  // Materias (tabs)
  List<String> _materias = [];
  late TabController _tabController;

  // Animaciones
  late AnimationController _headerCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;
  late Animation<double> _shimmer;

  // ── Colores y íconos por materia ─────────────────────────
  static const Map<String, Color> _materiaColors = {
    'matemáticas': Color(0xFF1565C0),
    'lenguaje':    Color(0xFF6A1B9A),
    'ciencias':    Color(0xFF2E7D32),
    'historia':    Color(0xFF4E342E),
    'inglés':      Color(0xFF00838F),
    'física':      Color(0xFFE65100),
    'informática': Color(0xFF37474F),
    'arte':        Color(0xFFAD1457),
    'química':     Color(0xFF00695C),
    'biología':    Color(0xFF1B5E20),
  };

  static const Map<String, IconData> _materiaIcons = {
    'matemáticas': Icons.calculate_rounded,
    'lenguaje':    Icons.menu_book_rounded,
    'ciencias':    Icons.science_rounded,
    'historia':    Icons.account_balance_rounded,
    'inglés':      Icons.language_rounded,
    'física':      Icons.sports_soccer_rounded,
    'informática': Icons.computer_rounded,
    'arte':        Icons.palette_rounded,
    'química':     Icons.biotech_rounded,
    'biología':    Icons.eco_rounded,
  };

  Color _colorForMateria(String m) {
    final key = m.toLowerCase();
    for (final k in _materiaColors.keys) {
      if (key.contains(k)) return _materiaColors[k]!;
    }
    return const Color(0xFF37474F);
  }

  IconData _iconForMateria(String m) {
    final key = m.toLowerCase();
    for (final k in _materiaIcons.keys) {
      if (key.contains(k)) return _materiaIcons[k]!;
    }
    return Icons.book_rounded;
  }

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmer = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );

    // TabController inicial con solo "Todas"
    _tabController = TabController(length: 1, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) return;
    _isInit = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _teacherId   = args?['_id']   as String?;
    _teacherName = args?['name']  as String? ?? 'Docente';
    _headerCtrl.forward();
    _fetchTasks();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _shimmerCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // ── Cargar tareas entregadas ──────────────────────────────
  Future<void> _fetchTasks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final tasks = await _api.getSubmittedAgendaTasks(
        teacherId: (_teacherId != null && _teacherId!.isNotEmpty) ? _teacherId : null,
      );
      if (!mounted) return;

      // Extraer materias únicas (ordenadas alfabéticamente)
      final Set<String> materiasSet = {};
      for (final t in tasks) {
        final subj = (t['subject'] as String?) ?? '';
        if (subj.trim().isNotEmpty) materiasSet.add(subj.trim());
      }
      final sortedMaterias = materiasSet.toList()..sort();

      // Recrear TabController con el número correcto de tabs
      _tabController.dispose();
      _tabController = TabController(
        length: sortedMaterias.length + 1, // +1 para "Todas"
        vsync: this,
      );

      setState(() {
        _allTasks = tasks;
        _materias = sortedMaterias;
        _isLoading = false;
      });
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

  // ── Filtrar por materia ───────────────────────────────────
  List<dynamic> _tasksByMateria(String? materia) {
    if (materia == null) return _allTasks;
    return _allTasks
        .where((t) => (t['subject'] as String? ?? '').trim() == materia)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: RefreshIndicator(
        onRefresh: _fetchTasks,
        color: const Color(0xFF1A237E),
        child: NestedScrollView(
          headerSliverBuilder: (ctx, inner) => [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildStatsRow()),
            if (!_isLoading && _materias.isNotEmpty)
              SliverToBoxAdapter(child: _buildTabBar()),
          ],
          body: _isLoading
              ? _buildShimmer()
              : _allTasks.isEmpty
                  ? _buildEmpty()
                  : _buildTabBarView(),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerCtrl,
      builder: (_, __) => SlideTransition(
        position: _headerSlide,
        child: FadeTransition(
          opacity: _headerOpacity,
          child: Container(
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
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
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Ícono
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
                          )
                        ],
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded,
                          color: Color(0xFF0D1B4E), size: 24),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tareas Entregadas',
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

                    // Badge total
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFFE53935).withOpacity(0.9),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53935).withOpacity(0.4),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pending_actions_rounded,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${_allTasks.length}',
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

  // ── Estadísticas resumen ──────────────────────────────────
  Widget _buildStatsRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildStatChip(
            '${_allTasks.length}',
            'Total',
            const Color(0xFF1A237E),
            Icons.assignment_rounded,
          ),
          const SizedBox(width: 10),
          _buildStatChip(
            '${_materias.length}',
            'Materias',
            const Color(0xFF2E7D32),
            Icons.class_rounded,
          ),
          const SizedBox(width: 10),
          _buildStatChip(
            _isLoading ? '...' : 'PDF',
            'Adjuntos',
            const Color(0xFFE53935),
            Icons.picture_as_pdf_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab Bar por materia ───────────────────────────────────
  Widget _buildTabBar() {
    final tabs = ['Todas', ..._materias];
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFF1A237E),
            unselectedLabelColor: Colors.grey[500],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            indicatorColor: const Color(0xFF1A237E),
            indicatorWeight: 3,
            dividerColor: Colors.transparent,
            tabs: tabs.map((t) {
              final count = t == 'Todas'
                  ? _allTasks.length
                  : _tasksByMateria(t).length;
              final color = t == 'Todas'
                  ? const Color(0xFF1A237E)
                  : _colorForMateria(t);
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (t != 'Todas') ...[
                      Icon(_iconForMateria(t), size: 14, color: color),
                      const SizedBox(width: 5),
                    ],
                    Text(t),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Vista de tabs ─────────────────────────────────────────
  Widget _buildTabBarView() {
    final tabs = [null, ..._materias]; // null = "Todas"
    return TabBarView(
      controller: _tabController,
      children: tabs.map((materia) {
        final tasks = _tasksByMateria(materia);
        if (tasks.isEmpty) {
          return _buildEmptyTab(materia);
        }
        return _buildTaskList(tasks, materia);
      }).toList(),
    );
  }

  Widget _buildTaskList(List<dynamic> tasks, String? materia) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      itemCount: tasks.length,
      itemBuilder: (_, i) => _buildTaskCard(tasks[i]),
    );
  }

  // ── Tarjeta de tarea ──────────────────────────────────────
  final Map<int, bool> _pressed = {};

  Widget _buildTaskCard(dynamic task) {
    final student      = task['userId'];
    final studentName  = (student is Map) ? (student['name']  ?? 'Estudiante') : 'Estudiante';
    final studentGrade = (student is Map) ? (student['grade'] ?? '') : '';
    final subject      = (task['subject'] as String?) ?? 'Sin materia';
    final title        = (task['title']   as String?) ?? 'Sin título';
    final note         = task['pdfSubmission']?['note'] as String?;
    final submittedAt  = task['pdfSubmission']?['submittedAt'] != null
        ? DateTime.tryParse(task['pdfSubmission']['submittedAt'])
        : null;

    final color  = _colorForMateria(subject);
    final index  = _allTasks.indexOf(task);
    final isPressed = _pressed[index] ?? false;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed[index] = true),
      onTapUp: (_) => setState(() => _pressed[index] = false),
      onTapCancel: () => setState(() => _pressed[index] = false),
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          '/teacher-grade',
          arguments: {
            'task':        task,
            'teacherId':   _teacherId,
            'teacherName': _teacherName,
          },
        );
        if (result == true) _fetchTasks();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 14),
        transformAlignment: Alignment.center,
        transform: isPressed
            ? (Matrix4.identity()..scale(0.97))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(isPressed ? 0.06 : 0.18),
              blurRadius: isPressed ? 8 : 22,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Barra de color de materia ─────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.5)],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fila 1: materia + icono + badge PDF
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.65)],
                          ),
                          boxShadow: [
                            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8),
                          ],
                        ),
                        child: Icon(_iconForMateria(subject),
                            color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.toUpperCase(),
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                            Text(
                              title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Color(0xFF0D1B4E),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Badge PDF
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE53935).withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.picture_as_pdf_rounded,
                                color: Color(0xFFE53935), size: 12),
                            SizedBox(width: 3),
                            Text(
                              'PDF',
                              style: TextStyle(
                                color: Color(0xFFE53935),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Nota del estudiante (si existe)
                  if (note != null && note.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F7FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF1A237E).withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote_rounded,
                              color: color.withOpacity(0.5), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              note,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),
                  const SizedBox(height: 10),

                  // Fila 2: estudiante + fecha + flecha
                  Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: color.withOpacity(0.12),
                        child: Text(
                          studentName.isNotEmpty
                              ? studentName[0].toUpperCase()
                              : 'E',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
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
                            if (studentGrade.toString().isNotEmpty)
                              Text(
                                studentGrade.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (submittedAt != null) ...[
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.upload_rounded,
                                    size: 10, color: Color(0xFF43A047)),
                                const SizedBox(width: 2),
                                const Text(
                                  'Entregado',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF43A047),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              DateFormat('dd MMM', 'es_ES')
                                  .format(submittedAt.toLocal()),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A237E),
                              ),
                            ),
                            Text(
                              DateFormat('HH:mm', 'es_ES')
                                  .format(submittedAt.toLocal()),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(width: 8),
                      // Botón calificar
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.75)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.grading_rounded,
                                color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Calificar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Estado vacío por tab ──────────────────────────────────
  Widget _buildEmptyTab(String? materia) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF43A047).withOpacity(0.1),
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 46, color: Color(0xFF43A047)),
            ),
            const SizedBox(height: 16),
            Text(
              materia == null
                  ? '¡Todo al día!'
                  : 'Sin tareas en $materia',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No hay tareas pendientes de calificación.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Estado vacío general ──────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF43A047).withOpacity(0.12),
                    const Color(0xFF2E7D32).withOpacity(0.06),
                  ],
                ),
              ),
              child: const Icon(Icons.assignment_turned_in_rounded,
                  size: 54, color: Color(0xFF43A047)),
            ),
            const SizedBox(height: 20),
            const Text(
              '¡Todo revisado!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No hay tareas entregadas pendientes de calificación.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchTasks,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shimmer de carga ──────────────────────────────────────
  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, __) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        itemCount: 4,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 160,
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
}
