// ============================================================
// screens/teacher_grade_history_screen.dart — Historial de Calificaciones
// ============================================================
// Pantalla del docente que muestra TODAS las tareas ya calificadas
// por él. Permite:
//   - Ver el historial completo de calificaciones con filtros
//   - Buscar por nombre de estudiante o materia
//   - Editar la nota y/o el comentario de una calificación existente
//   - Ver el promedio general de las notas dadas
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class TeacherGradeHistoryScreen extends StatefulWidget {
  const TeacherGradeHistoryScreen({super.key});

  @override
  State<TeacherGradeHistoryScreen> createState() =>
      _TeacherGradeHistoryScreenState();
}

class _TeacherGradeHistoryScreenState extends State<TeacherGradeHistoryScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchCtrl = TextEditingController();

  String? _teacherId;
  String? _teacherName;

  List<dynamic> _allGrades = [];
  List<dynamic> _filtered  = [];
  bool _isLoading = true;
  bool _isInit    = false;

  // Filtro de materia
  String? _selectedSubject;
  List<String> _subjects = ['Todas'];

  // Controladores de animación
  late AnimationController _headerCtrl;
  late AnimationController _listCtrl;
  late AnimationController _shimmerCtrl;
  late Animation<double> _headerOpacity;
  late Animation<Offset>  _headerSlide;
  late Animation<double>  _shimmer;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600));
    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOut)));
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _listCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));

    _shimmerCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _shimmer = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut));

    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _teacherId   = args?['_id']  ?? args?['teacherId'] ?? '';
      _teacherName = args?['name'] ?? args?['teacherName'] ?? 'Docente';
      _headerCtrl.forward();
      _fetchGrades();
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _listCtrl.dispose();
    _shimmerCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Carga de datos ─────────────────────────────────────────

  Future<void> _fetchGrades() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getGradedTasksByTeacher(_teacherId ?? '');
      if (!mounted) return;

      // Extraer materias únicas para el filtro
      final subjectSet = <String>{};
      for (final t in data) {
        final s = (t['subject'] as String? ?? '').trim();
        if (s.isNotEmpty) subjectSet.add(s);
      }

      setState(() {
        _allGrades = data;
        _subjects  = ['Todas', ...subjectSet.toList()..sort()];
        _isLoading = false;
      });
      _applyFilter();
      _listCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack('Error al cargar historial: $e', isError: true);
    }
  }

  void _applyFilter() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtered = _allGrades.where((t) {
        // Filtro de materia
        if (_selectedSubject != null && _selectedSubject != 'Todas') {
          final sub = (t['subject'] as String? ?? '').toLowerCase();
          if (!sub.contains(_selectedSubject!.toLowerCase())) return false;
        }
        // Filtro de búsqueda
        if (query.isNotEmpty) {
          final student = t['userId'];
          final name = (student is Map ? (student['name'] as String? ?? '') : '').toLowerCase();
          final title = (t['title'] as String? ?? '').toLowerCase();
          final subj  = (t['subject'] as String? ?? '').toLowerCase();
          if (!name.contains(query) && !title.contains(query) && !subj.contains(query)) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  // ── Editar calificación ────────────────────────────────────

  Future<void> _editGrade(dynamic task) async {
    final currentGrade   = (task['grade'] as num?)?.toInt() ?? 0;
    final currentComment = task['teacherComment'] as String? ?? '';
    final taskId  = task['_id'] as String? ?? '';
    final taskTitle = task['title'] as String? ?? 'Sin título';

    final gradeCtrl   = TextEditingController(text: currentGrade.toString());
    final commentCtrl = TextEditingController(text: currentComment);
    final formKey     = GlobalKey<FormState>();
    bool isSaving     = false;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 44, height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Título
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1A237E), Color(0xFF283593)]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Editar Calificación',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFF0D1B4E),
                                ),
                              ),
                              Text(
                                taskTitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Campo de nota
                    TextFormField(
                      controller: gradeCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Nota (0 – 100)',
                        prefixIcon: const Icon(Icons.grade_rounded,
                            color: Color(0xFF1A237E)),
                        filled: true,
                        fillColor: const Color(0xFFF0F4FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFF1A237E), width: 2)),
                        labelStyle: const TextStyle(color: Color(0xFF1A237E)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Ingresa una nota';
                        final n = int.tryParse(v);
                        if (n == null || n < 0 || n > 100) {
                          return 'La nota debe estar entre 0 y 100';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Campo de comentario
                    TextFormField(
                      controller: commentCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Comentario / Retroalimentación',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 40),
                          child: Icon(Icons.comment_rounded,
                              color: Color(0xFF1A237E))),
                        filled: true,
                        fillColor: const Color(0xFFF0F4FF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFF1A237E), width: 2)),
                        labelStyle: const TextStyle(color: Color(0xFF1A237E)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botones
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving ? null : () => Navigator.pop(ctx, false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFF1A237E)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Cancelar',
                                style: TextStyle(color: Color(0xFF1A237E))),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setModalState(() => isSaving = true);
                                    try {
                                      await _apiService.updateGrade(
                                        taskId,
                                        int.parse(gradeCtrl.text),
                                        _teacherId ?? '',
                                        comment: commentCtrl.text.trim(),
                                      );
                                      if (ctx.mounted) Navigator.pop(ctx, true);
                                    } catch (e) {
                                      setModalState(() => isSaving = false);
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ));
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A237E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                              elevation: 0,
                            ),
                            child: isSaving
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.save_rounded, size: 18),
                                      SizedBox(width: 6),
                                      Text('Guardar Cambios',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );

    if (result == true) {
      _showSnack('✅ Calificación actualizada correctamente');
      await _fetchGrades();
    }
  }

  // ── Helpers de UI ──────────────────────────────────────────

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF1A237E),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  double get _average {
    if (_filtered.isEmpty) return 0;
    final sum = _filtered.fold<double>(
        0, (acc, t) => acc + ((t['grade'] as num?)?.toDouble() ?? 0));
    return sum / _filtered.length;
  }

  Color _gradeColor(int grade) {
    if (grade >= 90) return const Color(0xFF1B5E20);
    if (grade >= 75) return const Color(0xFF2E7D32);
    if (grade >= 60) return const Color(0xFFFF8F00);
    if (grade >= 51) return const Color(0xFFE65100);
    return const Color(0xFFC62828);
  }

  Color _subjectColor(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('mat'))  return const Color(0xFF1565C0);
    if (s.contains('leng')) return const Color(0xFF6A1B9A);
    if (s.contains('cien')) return const Color(0xFF2E7D32);
    if (s.contains('hist')) return const Color(0xFFBF360C);
    if (s.contains('ingl')) return const Color(0xFF00838F);
    if (s.contains('fís'))  return const Color(0xFFE65100);
    return const Color(0xFF37474F);
  }

  IconData _subjectIcon(String subject) {
    final s = subject.toLowerCase();
    if (s.contains('mat'))  return Icons.calculate_rounded;
    if (s.contains('leng')) return Icons.menu_book_rounded;
    if (s.contains('cien')) return Icons.science_rounded;
    if (s.contains('hist')) return Icons.account_balance_rounded;
    if (s.contains('ingl')) return Icons.language_rounded;
    if (s.contains('fís'))  return Icons.sports_soccer_rounded;
    return Icons.book_rounded;
  }

  // ── Build ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          _buildFilterChips(),
          _buildStatsRow(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerCtrl,
      builder: (context2, anim2) => SlideTransition(
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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fila de navegación
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white.withValues(alpha: 0.12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF43A047), Color(0xFF1B5E20)]),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF43A047).withValues(alpha: 0.4),
                                blurRadius: 12),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.history_edu_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Historial de Calificaciones',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  fontSize: 11),
                              ),
                              Text(
                                _teacherName ?? 'Docente',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // Badge total
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 11, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF43A047).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF43A047).withValues(alpha: 0.4),
                                blurRadius: 10),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                '${_allGrades.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tarjetas de estadísticas del header
                    Row(
                      children: [
                        _buildStatCard(
                          icon: Icons.bar_chart_rounded,
                          label: 'Promedio',
                          value: _isLoading
                              ? '—'
                              : _average.toStringAsFixed(1),
                          color: const Color(0xFFFFC107),
                        ),
                        const SizedBox(width: 10),
                        _buildStatCard(
                          icon: Icons.trending_up_rounded,
                          label: 'Aprobados',
                          value: _isLoading
                              ? '—'
                              : '${_filtered.where((t) => ((t['grade'] as num?)?.toInt() ?? 0) >= 51).length}',
                          color: const Color(0xFF43A047),
                        ),
                        const SizedBox(width: 10),
                        _buildStatCard(
                          icon: Icons.trending_down_rounded,
                          label: 'Reprobados',
                          value: _isLoading
                              ? '—'
                              : '${_filtered.where((t) => ((t['grade'] as num?)?.toInt() ?? 0) < 51).length}',
                          color: const Color(0xFFE53935),
                        ),
                      ],
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ── Barra de búsqueda ──────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        decoration: InputDecoration(
          hintText: 'Buscar por estudiante, materia o título…',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFF1A237E), size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    _applyFilter();
                  },
                  child: const Icon(Icons.clear_rounded,
                      color: Color(0xFF1A237E), size: 18))
              : null,
          filled: true,
          fillColor: const Color(0xFFF0F4FF),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF1A237E), width: 1.5)),
        ),
      ),
    );
  }

  // ── Chips de filtro por materia ────────────────────────────

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _subjects.map((s) {
            final sel = (_selectedSubject == s) ||
                (_selectedSubject == null && s == 'Todas');
            return GestureDetector(
              onTap: () {
                setState(() =>
                    _selectedSubject = s == 'Todas' ? null : s);
                _applyFilter();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: sel
                      ? const LinearGradient(
                          colors: [Color(0xFF1A237E), Color(0xFF283593)])
                      : null,
                  color: sel ? null : const Color(0xFFF0F4FF),
                  boxShadow: sel
                      ? [BoxShadow(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.25),
                          blurRadius: 8, offset: const Offset(0, 3))]
                      : null,
                ),
                child: Text(
                  s,
                  style: TextStyle(
                    color: sel ? Colors.white : const Color(0xFF1A237E),
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Fila de estadísticas ───────────────────────────────────

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4, height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF43A047), Color(0xFF1A237E)]),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _isLoading
                ? 'Cargando historial…'
                : '${_filtered.length} calificación${_filtered.length != 1 ? 'es' : ''} encontrada${_filtered.length != 1 ? 's' : ''}',
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
              fontSize: 13),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _fetchGrades,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A237E).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh_rounded,
                  color: Color(0xFF1A237E), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Cuerpo ─────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_filtered.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context2, anim2) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, i) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment(_shimmer.value - 1, 0),
              end: Alignment(_shimmer.value, 0),
              colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF43A047).withValues(alpha: 0.12),
                    const Color(0xFF1B5E20).withValues(alpha: 0.06),
                  ]),
              ),
              child: const Center(
                child: Icon(Icons.history_edu_rounded,
                    size: 50, color: Color(0xFF43A047)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sin calificaciones aún',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E)),
            ),
            const SizedBox(height: 10),
            Text(
              _searchCtrl.text.isNotEmpty || _selectedSubject != null
                  ? 'No hay resultados para los filtros aplicados.\nIntenta con otros términos.'
                  : 'Aquí aparecerán todas las tareas que\nhayas calificado a tus estudiantes.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return AnimatedBuilder(
      animation: _listCtrl,
      builder: (context2, anim2) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        itemCount: _filtered.length,
        itemBuilder: (_, i) {
          final progress = (_listCtrl.value - i * 0.08).clamp(0.0, 1.0);
          final curved  = Curves.easeOutCubic.transform(progress);
          return Opacity(
            opacity: curved,
            child: Transform.translate(
              offset: Offset(0, (1 - curved) * 30),
              child: _buildGradeCard(_filtered[i]),
            ),
          );
        },
      ),
    );
  }

  // ── Tarjeta de calificación ────────────────────────────────

  Widget _buildGradeCard(dynamic task) {
    final student     = task['userId'];
    final studentName = (student is Map) ? (student['name'] ?? 'Estudiante') : 'Estudiante';
    final studentGrade= (student is Map) ? (student['grade'] ?? '') : '';
    final subject     = task['subject'] ?? 'Sin materia';
    final title       = task['title']   ?? 'Sin título';
    final grade       = (task['grade']  as num?)?.toInt() ?? 0;
    final comment     = task['teacherComment'] as String? ?? '';
    final gradedAt    = task['gradedAt'] != null
        ? DateTime.tryParse(task['gradedAt'])
        : null;

    final color      = _subjectColor(subject);
    final gradeColor = _gradeColor(grade);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 6)),
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior: icono + datos + nota
            Row(
              children: [
                // Ícono de materia
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, color.withValues(alpha: 0.6)]),
                    boxShadow: [
                      BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)],
                  ),
                  child: Center(
                    child: Icon(_subjectIcon(subject),
                        color: Colors.white, size: 20)),
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
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0D1B4E)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Burbuja de nota
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: gradeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: gradeColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$grade',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: gradeColor),
                      ),
                      Text(
                        '/100',
                        style: TextStyle(
                          fontSize: 9,
                          color: gradeColor.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            const SizedBox(height: 10),

            // Fila inferior: estudiante + fecha + botón editar
            Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundColor: const Color(0xFF1A237E).withValues(alpha: 0.1),
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : 'E',
                    style: const TextStyle(
                      color: Color(0xFF1A237E),
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
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
                          fontSize: 12,
                          color: Color(0xFF0D1B4E)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (studentGrade.toString().isNotEmpty)
                        Text(
                          studentGrade.toString(),
                          style: TextStyle(
                            fontSize: 10, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
                if (gradedAt != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('dd MMM yyyy', 'es_ES').format(gradedAt.toLocal()),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A237E)),
                      ),
                      Text(
                        DateFormat('HH:mm', 'es_ES').format(gradedAt.toLocal()),
                        style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                ],
                // Botón editar
                GestureDetector(
                  onTap: () => _editGrade(task),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1A237E), Color(0xFF283593)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A237E).withValues(alpha: 0.25),
                          blurRadius: 8, offset: const Offset(0, 3)),
                      ],
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),

            // Comentario del docente (si existe)
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.comment_rounded,
                        size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        comment,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                          height: 1.4,
                          fontStyle: FontStyle.italic),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
