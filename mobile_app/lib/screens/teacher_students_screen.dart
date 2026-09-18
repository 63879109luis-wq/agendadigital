// ============================================================
// screens/teacher_students_screen.dart — Mis Estudiantes (Docente)
// ============================================================
// Muestra al docente la lista de estudiantes inscritos en sus
// materias. Las inscripciones y materias asignadas son gestionadas
// por el Administrador desde el panel web-admin.
//
// Funcionalidades:
//   - Lista agrupada por materia con cabecera de color
//   - Buscador de estudiantes (nombre / C.I. / tutor)
//   - Filtro de chips por materia con contador
//   - Tarjetas con datos del estudiante y tutor
//   - Estado vacío informativo con instrucciones para el admin
//   - Pull-to-refresh y shimmer de carga
// ============================================================

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TeacherStudentsScreen extends StatefulWidget {
  const TeacherStudentsScreen({super.key});

  @override
  State<TeacherStudentsScreen> createState() => _TeacherStudentsScreenState();
}

class _TeacherStudentsScreenState extends State<TeacherStudentsScreen>
    with TickerProviderStateMixin {
  final ApiService _api = ApiService();

  String? _teacherId;
  String? _teacherName;

  // ── Estado ─────────────────────────────────────────────────
  bool _isLoading = true;
  String? _error;
  bool _isInit = false;

  List<dynamic> _materias = [];
  Map<String, List<dynamic>> _porMateria = {};
  List<dynamic> _todosEstudiantes = [];

  // ── Filtros ─────────────────────────────────────────────────
  String? _selectedMateria;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  // ── Animaciones ─────────────────────────────────────────────
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
      CurvedAnimation(
          parent: _headerCtrl,
          curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _headerSlide =
        Tween<Offset>(begin: const Offset(0, -0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic),
    );

    _listCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));

    _shimmerCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
          ..repeat();
    _shimmer = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _teacherId   = args?['_id']  ?? '';
      _teacherName = args?['name'] ?? 'Docente';
      _headerCtrl.forward();
      _cargarEstudiantes();
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

  // ── Carga de datos ──────────────────────────────────────────

  Future<void> _cargarEstudiantes() async {
    if (_teacherId == null || _teacherId!.isEmpty) {
      setState(() {
        _isLoading = false;
        _error = 'ID de docente no disponible';
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      debugPrint('🔍 Cargando estudiantes para docente: $_teacherId');
      final data = await _api.getEstudiantesDocente(_teacherId!);
      if (!mounted) return;

      debugPrint('📦 Respuesta del backend: ${data.keys.toList()}');
      debugPrint('📚 Materias: ${data['materias']?.length ?? 0}');
      debugPrint('👥 Estudiantes total: ${data['total'] ?? 0}');

      final materias = (data['materias'] as List<dynamic>?) ?? [];
      final porMateriaRaw =
          (data['porMateria'] as Map<String, dynamic>?) ?? {};
      final todos = (data['estudiantes'] as List<dynamic>?) ?? [];

      debugPrint('🗂️  porMateria keys: ${porMateriaRaw.keys.toList()}');
      porMateriaRaw.forEach((k, v) {
        debugPrint('   📋 $k → ${(v as List?)?.length ?? 0} estudiantes');
      });

      final Map<String, List<dynamic>> porMateria = {};
      porMateriaRaw.forEach((k, v) {
        porMateria[k] = (v as List<dynamic>?) ?? [];
      });

      setState(() {
        _materias         = materias;
        _porMateria       = porMateria;
        _todosEstudiantes = todos;
        _isLoading        = false;
      });
      _listCtrl.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      debugPrint('❌ Error al cargar estudiantes: $e');
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  // ── Helpers ─────────────────────────────────────────────────

  List<dynamic> get _estudiantesFiltrados {
    List<dynamic> base;
    if (_selectedMateria == null || _selectedMateria == 'Todas') {
      base = List.from(_todosEstudiantes);
    } else {
      base = List.from(_porMateria[_selectedMateria!] ?? []);
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      base = base.where((e) {
        final nombre = (e['nombre'] as String? ?? '').toLowerCase();
        final ci     = (e['ci']     as String? ?? '').toLowerCase();
        final curso  = (e['curso']  as String? ?? '').toLowerCase();
        final tutor  = (e['tutor']  as String? ?? '').toLowerCase();
        return nombre.contains(q) ||
            ci.contains(q) ||
            curso.contains(q) ||
            tutor.contains(q);
      }).toList();
    }
    return base;
  }

  Color _materiaColor(String nombre) {
    final colors = [
      const Color(0xFF1A237E),
      const Color(0xFF1B5E20),
      const Color(0xFF4A148C),
      const Color(0xFF880E4F),
      const Color(0xFF0D47A1),
      const Color(0xFFE65100),
      const Color(0xFF006064),
    ];
    return colors[nombre.hashCode.abs() % colors.length];
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: RefreshIndicator(
        onRefresh: _cargarEstudiantes,
        color: const Color(0xFF1A237E),
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildMateriaFilter(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _headerCtrl,
      builder: (context, child) => SlideTransition(
        position: _headerSlide,
        child: FadeTransition(
          opacity: _headerOpacity,
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D1B4E),
                  Color(0xFF1A237E),
                  Color(0xFF283593)
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 20),
                child: Row(
                  children: [
                    // Botón volver
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
                    // Ícono de grupo
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF26C6DA), Color(0xFF00838F)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF26C6DA)
                                .withValues(alpha: 0.4),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.groups_rounded,
                            color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mis Estudiantes',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 11,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            _teacherName ?? 'Docente',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Badge total
                    if (!_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFF26C6DA).withValues(alpha: 0.85),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF26C6DA)
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.person_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${_todosEstudiantes.length}',
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

  // ── Barra de búsqueda ───────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B4E)),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, C.I. o tutor…',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFF1A237E), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => setState(() {
                    _searchQuery = '';
                    _searchCtrl.clear();
                  }),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF0F4FF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  // ── Filtro de materias ──────────────────────────────────────

  Widget _buildMateriaFilter() {
    if (_materias.isEmpty && !_isLoading) return const SizedBox.shrink();

    final options = [
      'Todas',
      ..._materias.map((m) => m['nombre'] as String? ?? '')
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: options.map((materia) {
            final isSelected = (_selectedMateria == materia) ||
                (_selectedMateria == null && materia == 'Todas');
            final color = materia == 'Todas'
                ? const Color(0xFF1A237E)
                : _materiaColor(materia);

            return GestureDetector(
              onTap: () => setState(() {
                _selectedMateria = materia == 'Todas' ? null : materia;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isSelected ? color : const Color(0xFFF0F4FF),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: color.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3))
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (materia != 'Todas') ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.9)
                              : color,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      materia,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF1A237E),
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                    ),
                    // Contador de estudiantes en esta materia
                    if (materia != 'Todas' && _porMateria[materia] != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : color.withValues(alpha: 0.15),
                        ),
                        child: Text(
                          '${_porMateria[materia]!.length}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Cuerpo ──────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) return _buildShimmer();
    if (_error != null) return _buildError();

    final estudiantes = _estudiantesFiltrados;

    if (_todosEstudiantes.isEmpty) {
      return _buildEmptyNoEstudiantes();
    }
    if (estudiantes.isEmpty && _searchQuery.isNotEmpty) {
      return _buildEmptySearch();
    }
    if (_selectedMateria != null && estudiantes.isEmpty) {
      return _buildEmptyMateria();
    }

    if (_selectedMateria == null && _searchQuery.isEmpty) {
      return _buildGroupedList();
    }

    return _buildFlatList(estudiantes);
  }

  // ── Shimmer de carga ────────────────────────────────────────

  Widget _buildShimmer() {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (context, child) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        itemCount: 5,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
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

  // ── Lista agrupada por materia ──────────────────────────────

  Widget _buildGroupedList() {
    return AnimatedBuilder(
      animation: _listCtrl,
      builder: (context, child) => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        itemCount: _materias.length,
        itemBuilder: (context, i) {
          final materia = _materias[i];
          final nombre  = materia['nombre'] as String? ?? 'Sin nombre';
          final area    = materia['area']   as String? ?? '';
          final lista   = _porMateria[nombre] ?? [];
          final color   = _materiaColor(nombre);

          final progress =
              (_listCtrl.value - i * 0.12).clamp(0.0, 1.0);
          final curved = Curves.easeOutCubic.transform(progress);

          return Opacity(
            opacity: curved,
            child: Transform.translate(
              offset: Offset(0, (1 - curved) * 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera de materia — sin const para que `i` sea dinámico
                  Container(
                    margin: EdgeInsets.only(bottom: 8, top: i == 0 ? 0 : 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.75)],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.book_rounded,
                              color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (area.isNotEmpty)
                                Text(
                                  area,
                                  style: TextStyle(
                                    color: Colors.white
                                        .withValues(alpha: 0.75),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_rounded,
                                  color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                '${lista.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Estudiantes de esta materia
                  if (lista.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.person_off_rounded,
                                color: Colors.grey[300], size: 32),
                            const SizedBox(height: 6),
                            Text(
                              'Sin estudiantes inscritos en esta materia',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...lista.map((e) => _buildStudentCard(e, color)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Lista plana (búsqueda / materia filtrada) ───────────────

  Widget _buildFlatList(List<dynamic> estudiantes) {
    final color = _selectedMateria != null
        ? _materiaColor(_selectedMateria!)
        : const Color(0xFF1A237E);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
      itemCount: estudiantes.length,
      itemBuilder: (context, i) {
        final progress = Curves.easeOutCubic.transform(
          ((i + 1) / estudiantes.length).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: progress,
          child: _buildStudentCard(estudiantes[i], color),
        );
      },
    );
  }

  // ── Tarjeta de estudiante ───────────────────────────────────

  Widget _buildStudentCard(dynamic insc, Color color) {
    final nombre   = insc['nombre']   as String? ?? 'Estudiante';
    final ci       = insc['ci']       as String? ?? '—';
    final curso    = insc['curso']    as String? ?? '—';
    final tutor    = insc['tutor']    as String? ?? '';
    final tutorTel = insc['tutorTel'] as String? ?? '';
    final gestion  = insc['gestion']  as String? ?? '';

    // Iniciales del avatar
    final words    = nombre.trim().split(' ');
    final initials = words.length >= 2
        ? '${words[0][0]}${words[1][0]}'.toUpperCase()
        : nombre.substring(0, nombre.length.clamp(0, 2)).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
                boxShadow: [
                  BoxShadow(
                      color: color.withValues(alpha: 0.3), blurRadius: 8),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: Color(0xFF0D1B4E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text('C.I: $ci',
                          style: TextStyle(
                              fontSize: 11.5, color: Colors.grey[600])),
                      const SizedBox(width: 10),
                      Icon(Icons.school_outlined,
                          size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          curso,
                          style: TextStyle(
                              fontSize: 11.5, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (tutor.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.supervisor_account_outlined,
                            size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Tutor: $tutor${tutorTel.isNotEmpty ? " · $tutorTel" : ""}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Badges laterales
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            const Color(0xFF43A047).withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    '✓ Inscrito',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (gestion.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    gestion,
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Estados vacíos ──────────────────────────────────────────

  Widget _buildEmptyNoEstudiantes() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
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
                    const Color(0xFF26C6DA).withValues(alpha: 0.15),
                    const Color(0xFF1A237E).withValues(alpha: 0.07),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.groups_outlined,
                    size: 52, color: Color(0xFF26C6DA)),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'Sin estudiantes inscritos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Aún no hay estudiantes inscritos en tus materias.\n\n'
              'El administrador debe registrarlos desde el panel web '
              'en la sección "Inscripción" y asignar tu materia.',
              style: TextStyle(
                  fontSize: 13.5, color: Colors.grey[600], height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: const Color(0xFF90CAF9).withValues(alpha: 0.6)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF1A237E).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline_rounded,
                        color: Color(0xFF1A237E), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'El administrador va a "Inscripción" en el panel web '
                      'y completa los datos del estudiante asignando tu materia.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1565C0),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarEstudiantes,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Actualizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
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

  Widget _buildEmptySearch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Sin resultados para "$_searchQuery"',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A237E)),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => setState(() {
              _searchQuery = '';
              _searchCtrl.clear();
            }),
            icon: const Icon(Icons.clear_rounded),
            label: const Text('Limpiar búsqueda'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMateria() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search_rounded,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Sin estudiantes en "$_selectedMateria"',
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A237E)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'El administrador aún no ha inscrito\nestudiantes en esta materia.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
              ),
              child: const Center(
                child: Icon(Icons.cloud_off_rounded,
                    size: 42, color: Color(0xFFE53935)),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Error de conexión',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE53935)),
            ),
            const SizedBox(height: 10),
            Text(
              'No se pudo cargar la lista de estudiantes.\n'
              'Verifica la conexión al servidor.',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _cargarEstudiantes,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 13),
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
}
