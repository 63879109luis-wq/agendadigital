// ============================================================
// admin_dashboard_screen.dart — Panel Administrativo Completo
// ============================================================
// 10 módulos funcionales:
//  1. Dashboard   2. Administradores  3. Docentes   4. Estudiantes
//  5. Materias    6. Actividades      7. Agenda     8. Calificaciones
//  9. Reportes   10. Configuración
// ============================================================

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

// ── Paleta de colores ─────────────────────────────────────────
const _bg      = Color(0xFF0C1127);
const _surface = Color(0xFF0F1631);
const _card    = Color(0xFF0A0E24);
const _sidebar = Color(0xFF05091C);
const _blue    = Color(0xFF1E88E5);
const _gold    = Color(0xFFFFC107);
const _navy    = Color(0xFF0F52BA);
const _green   = Color(0xFF10B981);
const _purple  = Color(0xFF8B5CF6);
const _red     = Color(0xFFEF4444);

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {
  final _api = ApiService();
  String _selectedMenu = 'Dashboard';
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard',       'icon': Icons.dashboard_rounded,           'color': _blue},
    {'title': 'Administradores', 'icon': Icons.admin_panel_settings_rounded,'color': _purple},
    {'title': 'Docentes',        'icon': Icons.people_alt_rounded,          'color': _green},
    {'title': 'Estudiantes',     'icon': Icons.school_rounded,              'color': _gold},
    {'title': 'Materias',        'icon': Icons.menu_book_rounded,           'color': _blue},
    {'title': 'Actividades',     'icon': Icons.event_note_rounded,          'color': _red},
    {'title': 'Agenda',          'icon': Icons.calendar_today_rounded,      'color': _green},
    {'title': 'Calificaciones',  'icon': Icons.percent_rounded,             'color': _gold},
    {'title': 'Reportes',        'icon': Icons.bar_chart_rounded,           'color': _purple},
    {'title': 'Configuración',   'icon': Icons.settings_rounded,            'color': Colors.white60},
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _selectMenu(String title) {
    setState(() => _selectedMenu = title);
    _fadeCtrl.reset();
    _fadeCtrl.forward();
  }

  // ── SNACKBAR ──────────────────────────────────────────────
  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? _red : _green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size      = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1100;
    final args      = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final adminName  = args?['name']  ?? 'Administrador';
    final adminEmail = args?['email'] ?? 'admin@sistema.edu';

    return Scaffold(
      backgroundColor: _bg,
      appBar: !isDesktop ? _buildAppBar() : null,
      drawer: !isDesktop
          ? Drawer(backgroundColor: _sidebar, child: _buildSidebar(context))
          : null,
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 240, child: _buildSidebar(context)),
          Expanded(
            child: Column(
              children: [
                if (isDesktop) _buildHeader(adminName, adminEmail),
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: _buildCurrentModule(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() => AppBar(
    backgroundColor: _sidebar,
    foregroundColor: Colors.white,
    elevation: 0,
    title: Row(
      children: [
        Icon(_menuItems.firstWhere((m) => m['title'] == _selectedMenu)['icon'] as IconData,
            color: _gold, size: 18),
        const SizedBox(width: 8),
        Text(_selectedMenu,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    ),
    actions: [
      IconButton(
        icon: const Icon(Icons.logout_rounded),
        onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
      ),
    ],
  );

  // ── SIDEBAR ───────────────────────────────────────────────
  Widget _buildSidebar(BuildContext context) {
    return Container(
      color: _sidebar,
      child: Column(
        children: [
          const SizedBox(height: 36),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _navy.withOpacity(0.2),
                    border: Border.all(color: _gold, width: 1.5),
                  ),
                  child: const Icon(Icons.school_rounded, color: _gold, size: 22),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SISTEMA',   style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text('ACADÉMICO', style: TextStyle(color: _gold,        fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('MENÚ PRINCIPAL', style: TextStyle(color: Colors.white30, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (ctx, i) {
                final item = _menuItems[i];
                final isSelected = _selectedMenu == item['title'];
                final color = item['color'] as Color;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected ? Border.all(color: color.withOpacity(0.3)) : null,
                    ),
                    child: ListTile(
                      dense: true,
                      onTap: () {
                        _selectMenu(item['title'] as String);
                        if (MediaQuery.of(context).size.width < 1100) {
                          Navigator.pop(context);
                        }
                      },
                      leading: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item['icon'] as IconData, color: isSelected ? color : Colors.white60, size: 16),
                      ),
                      title: Text(
                        item['title'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle))
                          : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                );
              },
            ),
          ),
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_navy.withOpacity(0.3), _navy.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _navy.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: _gold, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Sistema Seguro', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('Protección de datos activa', style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 8)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HEADER DESKTOP ─────────────────────────────────────────
  Widget _buildHeader(String adminName, String adminEmail) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: _sidebar,
        border: Border(bottom: BorderSide(color: Color(0xFF0F1631), width: 1)),
      ),
      child: Row(
        children: [
          Text(_selectedMenu,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const Spacer(),
          // Búsqueda
          Container(
            width: 260,
            height: 36,
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.06)),
            ),
            child: TextField(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Buscar en $_selectedMenu...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 16),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Notificaciones
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(shape: BoxShape.circle, color: _surface),
                child: const Icon(Icons.notifications_none_rounded, color: _gold, size: 18),
              ),
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: _red, shape: BoxShape.circle),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Perfil
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: _gold.withOpacity(0.2),
                child: const Icon(Icons.person_rounded, color: _gold, size: 18),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(adminName,  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(adminEmail, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10)),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/login'),
                child: Icon(Icons.logout_rounded, color: Colors.white.withOpacity(0.4), size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── ROUTER DE MÓDULOS ─────────────────────────────────────
  Widget _buildCurrentModule() {
    switch (_selectedMenu) {
      case 'Dashboard':       return _DashboardModule(api: _api);
      case 'Administradores': return _UsersModule(api: _api, role: 'admin',   roleLabel: 'Administrador', onSnack: _snack);
      case 'Docentes':        return _UsersModule(api: _api, role: 'teacher', roleLabel: 'Docente',        onSnack: _snack);
      case 'Estudiantes':     return _UsersModule(api: _api, role: 'student', roleLabel: 'Estudiante',     onSnack: _snack);
      case 'Materias':        return _MateriasModule(api: _api, onSnack: _snack);
      case 'Actividades':     return _ActividadesModule(api: _api, onSnack: _snack);
      case 'Agenda':          return _AgendaModule(api: _api, onSnack: _snack);
      case 'Calificaciones':  return _CalificacionesModule(api: _api);
      case 'Reportes':        return _ReportesModule(api: _api);
      case 'Configuración':   return _ConfiguracionModule(onSnack: _snack);
      default:                return _DashboardModule(api: _api);
    }
  }
}

// ══════════════════════════════════════════════════════════════
// MÓDULO 1: DASHBOARD
// ══════════════════════════════════════════════════════════════
class _DashboardModule extends StatefulWidget {
  final ApiService api;
  const _DashboardModule({required this.api});
  @override
  State<_DashboardModule> createState() => _DashboardModuleState();
}
class _DashboardModuleState extends State<_DashboardModule> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final s = await widget.api.getAdminStats();
      if (mounted) setState(() { _stats = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _gold));
    final admins   = _stats?['admins']   ?? 0;
    final teachers = _stats?['teachers'] ?? 0;
    final students = _stats?['students'] ?? 0;
    final total    = _stats?['total']    ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bienvenida
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_navy, Color(0xFF1565C0)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('¡Bienvenido, Administrador!',
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(DateFormat('EEEE, d \'de\' MMMM yyyy', 'es').format(DateTime.now()),
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Métricas
          _sectionTitle('Resumen general', Icons.analytics_rounded),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _metricCard('Total usuarios', total.toString(), Icons.groups_rounded, _blue, 'En el sistema'),
              _metricCard('Administradores', admins.toString(), Icons.admin_panel_settings_rounded, _purple, 'Cuentas admin'),
              _metricCard('Docentes', teachers.toString(), Icons.people_alt_rounded, _green, 'Profesores activos'),
              _metricCard('Estudiantes', students.toString(), Icons.school_rounded, _gold, 'Matriculados'),
            ],
          ),
          const SizedBox(height: 20),
          _sectionTitle('Distribución de roles', Icons.pie_chart_rounded),
          const SizedBox(height: 12),
          _RoleChart(admins: admins, teachers: teachers, students: students),
          const SizedBox(height: 20),
          _sectionTitle('Acciones rápidas', Icons.bolt_rounded),
          const SizedBox(height: 12),
          _QuickActions(),
          const SizedBox(height: 20),
          _sectionTitle('Flujo del sistema', Icons.alt_route_rounded),
          const SizedBox(height: 12),
          _FlowCard(),
        ],
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, String sub) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 16),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(sub, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoleChart extends StatelessWidget {
  final int admins, teachers, students;
  const _RoleChart({required this.admins, required this.teachers, required this.students});

  @override
  Widget build(BuildContext context) {
    final total = (admins + teachers + students).toDouble();
    if (total == 0) return const SizedBox();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: CustomPaint(
              painter: _PiePainter([
                PieSlice(admins / total, _purple),
                PieSlice(teachers / total, _green),
                PieSlice(students / total, _gold),
              ]),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: [
                _legendRow('Administradores', admins, total, _purple),
                _legendRow('Docentes',        teachers, total, _green),
                _legendRow('Estudiantes',     students, total, _gold),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendRow(String label, int count, double total, Color color) {
    final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11))),
          Text('$count ($pct%)', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class PieSlice { final double fraction; final Color color; PieSlice(this.fraction, this.color); }
class _PiePainter extends CustomPainter {
  final List<PieSlice> slices;
  _PiePainter(this.slices);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    double start = -pi / 2;
    for (final s in slices) {
      final sweep = s.fraction * 2 * pi;
      canvas.drawArc(rect, start, sweep, true,
          Paint()..color = s.color..style = PaintingStyle.fill);
      canvas.drawArc(rect, start, sweep, true,
          Paint()..color = _bg..style = PaintingStyle.stroke..strokeWidth = 2);
      start += sweep;
    }
  }
  @override
  bool shouldRepaint(_PiePainter old) => false;
}

class _QuickActions extends StatelessWidget {
  final _actions = const [
    {'label': 'Nuevo admin',    'icon': Icons.admin_panel_settings_rounded, 'color': _purple},
    {'label': 'Nuevo docente',  'icon': Icons.person_add_rounded,           'color': _green},
    {'label': 'Nuevo estudiante','icon': Icons.school_rounded,              'color': _gold},
    {'label': 'Nueva materia',  'icon': Icons.menu_book_rounded,            'color': _blue},
  ];
  const _QuickActions();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: _actions.map((a) {
        final color = a['color'] as Color;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(a['icon'] as IconData, color: color, size: 22),
                  const SizedBox(height: 6),
                  Text(a['label'] as String,
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 9, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FlowCard extends StatelessWidget {
  final _steps = const [
    {'num': '1', 'title': 'Registro',     'icon': Icons.assignment_ind_rounded},
    {'num': '2', 'title': 'Asignación',   'icon': Icons.people_outline_rounded},
    {'num': '3', 'title': 'Matrícula',    'icon': Icons.person_add_alt_1_rounded},
    {'num': '4', 'title': 'Docente',      'icon': Icons.laptop_chromebook_rounded},
    {'num': '5', 'title': 'Actividades',  'icon': Icons.post_add_rounded},
    {'num': '6', 'title': 'Entrega',      'icon': Icons.cloud_done_rounded},
    {'num': '7', 'title': 'Calificación', 'icon': Icons.star_rounded},
  ];
  const _FlowCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.15), size: 14),
              );
            }
            final s = _steps[i ~/ 2];
            return SizedBox(
              width: 76,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _navy.withOpacity(0.3),
                      border: Border.all(color: _gold, width: 1.5),
                    ),
                    child: Center(child: Text(s['num'] as String,
                        style: const TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 12))),
                  ),
                  const SizedBox(height: 6),
                  Icon(s['icon'] as IconData, color: Colors.white60, size: 18),
                  const SizedBox(height: 4),
                  Text(s['title'] as String,
                      style: const TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MÓDULO 2/3/4: USUARIOS (Admin / Docentes / Estudiantes)
// ══════════════════════════════════════════════════════════════
class _UsersModule extends StatefulWidget {
  final ApiService api;
  final String role;
  final String roleLabel;
  final void Function(String, {bool error}) onSnack;
  const _UsersModule({required this.api, required this.role, required this.roleLabel, required this.onSnack});
  @override
  State<_UsersModule> createState() => _UsersModuleState();
}
class _UsersModuleState extends State<_UsersModule> {
  List<dynamic> _users = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load([String? search]) async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getUsers(role: widget.role, search: search);
      if (mounted) setState(() { _users = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      widget.onSnack('Error al cargar: $e', error: true);
    }
  }

  void _showForm([Map<String, dynamic>? user]) {
    final nameCtrl  = TextEditingController(text: user?['name'] ?? '');
    final emailCtrl = TextEditingController(text: user?['email'] ?? '');
    final passCtrl  = TextEditingController();
    final gradeCtrl = TextEditingController(text: user?['grade'] ?? '');
    final isEdit = user != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _navy.withOpacity(0.4))),
        title: Row(
          children: [
            Icon(isEdit ? Icons.edit_rounded : Icons.person_add_rounded, color: _gold, size: 20),
            const SizedBox(width: 8),
            Text(isEdit ? 'Editar ${widget.roleLabel}' : 'Nuevo ${widget.roleLabel}',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField('Nombre completo', nameCtrl, Icons.person_outline),
              const SizedBox(height: 10),
              _inputField('Correo electrónico', emailCtrl, Icons.email_outlined),
              const SizedBox(height: 10),
              _inputField(isEdit ? 'Nueva contraseña (opcional)' : 'Contraseña', passCtrl, Icons.lock_outline, obscure: true),
              if (widget.role == 'student') ...[
                const SizedBox(height: 10),
                _inputField('Curso (ej: 5A Sec)', gradeCtrl, Icons.class_outlined),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final data = <String, dynamic>{
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'role': widget.role,
                  if (gradeCtrl.text.isNotEmpty) 'grade': gradeCtrl.text.trim(),
                  if (passCtrl.text.isNotEmpty) 'password': passCtrl.text,
                };
                if (isEdit) {
                  await widget.api.updateUser(user!['_id'] as String, data);
                  widget.onSnack('${widget.roleLabel} actualizado');
                } else {
                  await widget.api.createUser(data);
                  widget.onSnack('${widget.roleLabel} creado');
                }
                _load(_searchCtrl.text.isNotEmpty ? _searchCtrl.text : null);
              } catch (e) {
                widget.onSnack('Error: $e', error: true);
              }
            },
            child: Text(isEdit ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  void _delete(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _red.withOpacity(0.4))),
        title: const Text('¿Eliminar usuario?', style: TextStyle(color: Colors.white)),
        content: Text('Se eliminará permanentemente a "${user['name']}".',
            style: TextStyle(color: Colors.white.withOpacity(0.6))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.api.deleteUser(user['_id'] as String);
                widget.onSnack('Usuario eliminado');
                _load();
              } catch (e) {
                widget.onSnack('Error: $e', error: true);
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color get _roleColor {
    switch (widget.role) {
      case 'admin':   return _purple;
      case 'teacher': return _green;
      default:        return _gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor;
    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.06)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Buscar ${widget.roleLabel.toLowerCase()}...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 18),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) => _load(v.isNotEmpty ? v : null),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Nuevo ${widget.roleLabel}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Stats bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.people_rounded, color: color, size: 16),
                const SizedBox(width: 8),
                Text('${_users.length} ${widget.roleLabel.toLowerCase()}${_users.length != 1 ? 's' : ''} encontrados',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Lista
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : _users.isEmpty
                  ? _emptyState('No hay ${widget.roleLabel.toLowerCase()}s registrados')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _users.length,
                      itemBuilder: (ctx, i) {
                        final u = _users[i] as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              radius: 22,
                              backgroundColor: color.withOpacity(0.15),
                              child: Text(
                                (u['name'] as String? ?? '?').isNotEmpty
                                    ? (u['name'] as String).substring(0, 1).toUpperCase()
                                    : '?',
                                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            title: Text(u['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(u['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                                if (u['grade'] != null && (u['grade'] as String).isNotEmpty)
                                  Text('Curso: ${u['grade']}', style: TextStyle(color: _gold.withOpacity(0.7), fontSize: 10)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: _green.withOpacity(0.3)),
                                  ),
                                  child: const Text('Activo', style: TextStyle(color: _green, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: _blue, size: 18),
                                  onPressed: () => _showForm(u),
                                  tooltip: 'Editar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_rounded, color: _red, size: 18),
                                  onPressed: () => _delete(u),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MÓDULO 5: MATERIAS
// ══════════════════════════════════════════════════════════════
class _MateriasModule extends StatefulWidget {
  final ApiService api;
  final void Function(String, {bool error}) onSnack;
  const _MateriasModule({required this.api, required this.onSnack});
  @override
  State<_MateriasModule> createState() => _MateriasModuleState();
}
class _MateriasModuleState extends State<_MateriasModule> {
  List<dynamic> _materias = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load([String? search]) async {
    setState(() => _loading = true);
    try {
      final data = await widget.api.getMaterias(search: search);
      if (mounted) setState(() { _materias = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForm([Map<String, dynamic>? m]) {
    final nombreCtrl  = TextEditingController(text: m?['nombre'] ?? '');
    final codigoCtrl  = TextEditingController(text: m?['codigo'] ?? '');
    final areaCtrl    = TextEditingController(text: m?['area'] ?? '');
    final semCtrl     = TextEditingController(text: m?['semestre'] ?? '');
    final descCtrl    = TextEditingController(text: m?['descripcion'] ?? '');
    final isEdit = m != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: _blue.withOpacity(0.3))),
        title: Row(children: [
          const Icon(Icons.menu_book_rounded, color: _blue, size: 20),
          const SizedBox(width: 8),
          Text(isEdit ? 'Editar Materia' : 'Nueva Materia',
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        ]),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _inputField('Nombre de la materia', nombreCtrl, Icons.book_outlined),
              const SizedBox(height: 10),
              _inputField('Código (ej: INF-101)', codigoCtrl, Icons.code_rounded),
              const SizedBox(height: 10),
              _inputField('Área (ej: Informática)', areaCtrl, Icons.category_outlined),
              const SizedBox(height: 10),
              _inputField('Semestre (ej: 3.° Semestre)', semCtrl, Icons.school_outlined),
              const SizedBox(height: 10),
              _inputField('Descripción', descCtrl, Icons.notes_rounded),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final data = {
                  'nombre': nombreCtrl.text.trim(),
                  'codigo': codigoCtrl.text.trim(),
                  'area': areaCtrl.text.trim(),
                  'semestre': semCtrl.text.trim(),
                  'descripcion': descCtrl.text.trim(),
                };
                if (isEdit) {
                  await widget.api.updateMateria(m!['_id'] as String, data);
                  widget.onSnack('Materia actualizada');
                } else {
                  await widget.api.createMateria(data);
                  widget.onSnack('Materia creada');
                }
                _load(_searchCtrl.text.isNotEmpty ? _searchCtrl.text : null);
              } catch (e) {
                widget.onSnack('Error: $e', error: true);
              }
            },
            child: Text(isEdit ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  void _delete(Map<String, dynamic> m) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _red.withOpacity(0.4))),
        title: const Text('¿Eliminar materia?', style: TextStyle(color: Colors.white)),
        content: Text('Se eliminará "${m['nombre']}".',
            style: TextStyle(color: Colors.white.withOpacity(0.6))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.api.deleteMateria(m['_id'] as String);
                widget.onSnack('Materia eliminada');
                _load();
              } catch (e) {
                widget.onSnack('Error: $e', error: true);
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: _searchBar('Buscar materia...', _searchCtrl, (v) => _load(v.isNotEmpty ? v : null)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nueva Materia'),
                style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : _materias.isEmpty
                  ? _emptyState('No hay materias registradas')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _materias.length,
                      itemBuilder: (ctx, i) {
                        final m = _materias[i] as Map<String, dynamic>;
                        final docente = m['docenteId'];
                        final docenteName = docente is Map ? docente['name'] ?? 'Sin asignar' : 'Sin asignar';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withOpacity(0.04)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: _blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.menu_book_rounded, color: _blue, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(child: Text(m['nombre'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: _navy.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                          child: Text(m['codigo'] ?? '', style: const TextStyle(color: _blue, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.folder_outlined, size: 11, color: Colors.white.withOpacity(0.4)),
                                        const SizedBox(width: 4),
                                        Text(m['area'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                                        const SizedBox(width: 12),
                                        Icon(Icons.person_outline, size: 11, color: Colors.white.withOpacity(0.4)),
                                        const SizedBox(width: 4),
                                        Text(docenteName, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                                        const SizedBox(width: 12),
                                        Icon(Icons.school_outlined, size: 11, color: Colors.white.withOpacity(0.4)),
                                        const SizedBox(width: 4),
                                        Text(m['semestre'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.edit_rounded, color: _blue, size: 18), onPressed: () => _showForm(m)),
                              IconButton(icon: const Icon(Icons.delete_rounded, color: _red, size: 18), onPressed: () => _delete(m)),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MÓDULO 6: ACTIVIDADES
// ══════════════════════════════════════════════════════════════
class _ActividadesModule extends StatefulWidget {
  final ApiService api;
  final void Function(String, {bool error}) onSnack;
  const _ActividadesModule({required this.api, required this.onSnack});
  @override
  State<_ActividadesModule> createState() => _ActividadesModuleState();
}
class _ActividadesModuleState extends State<_ActividadesModule> {
  List<dynamic> _actividades = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  String _filterTipo  = 'Todos';
  String _filterEstado = 'Todos';
  final _searchCtrl = TextEditingController();

  final _tipos   = ['Todos', 'Tarea', 'Examen', 'Cuestionario', 'Proyecto', 'Reunión'];
  final _estados = ['Todos', 'Activa', 'Próxima', 'Finalizada'];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        widget.api.getActividadesStats(),
        widget.api.getActividades(
          tipo:   _filterTipo   != 'Todos' ? _filterTipo   : null,
          estado: _filterEstado != 'Todos' ? _filterEstado : null,
          search: _searchCtrl.text.isNotEmpty ? _searchCtrl.text : null,
        ),
      ]);
      if (mounted) setState(() {
        _stats       = results[0] as Map<String, dynamic>;
        _actividades = results[1] as List;
        _loading     = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showForm([Map<String, dynamic>? a]) {
    final tituloCtrl = TextEditingController(text: a?['titulo'] ?? '');
    final descCtrl   = TextEditingController(text: a?['descripcion'] ?? '');
    String tipo      = a?['tipo'] ?? 'Tarea';
    String estado    = a?['estado'] ?? 'Próxima';
    DateTime fecha   = a?['fechaEntrega'] != null ? DateTime.tryParse(a!['fechaEntrega'] as String) ?? DateTime.now() : DateTime.now().add(const Duration(days: 7));
    final isEdit = a != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setForm) => AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: _red.withOpacity(0.3))),
          title: Row(children: [
            const Icon(Icons.event_note_rounded, color: _red, size: 20),
            const SizedBox(width: 8),
            Text(isEdit ? 'Editar Actividad' : 'Nueva Actividad',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _inputField('Título', tituloCtrl, Icons.title_rounded),
                const SizedBox(height: 10),
                _inputField('Descripción', descCtrl, Icons.notes_rounded),
                const SizedBox(height: 10),
                _dropdownField('Tipo', tipo, ['Tarea', 'Examen', 'Cuestionario', 'Proyecto', 'Reunión'],
                    (v) => setForm(() => tipo = v!), Icons.category_outlined),
                const SizedBox(height: 10),
                _dropdownField('Estado', estado, ['Activa', 'Próxima', 'Finalizada'],
                    (v) => setForm(() => estado = v!), Icons.flag_outlined),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: fecha,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setForm(() => fecha = d);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white54, size: 16),
                        const SizedBox(width: 10),
                        Text(DateFormat('dd/MM/yyyy').format(fecha),
                            style: const TextStyle(color: Colors.white, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  final data = {
                    'titulo': tituloCtrl.text.trim(),
                    'descripcion': descCtrl.text.trim(),
                    'tipo': tipo,
                    'estado': estado,
                    'fechaEntrega': fecha.toIso8601String(),
                  };
                  if (isEdit) {
                    await widget.api.updateActividad(a!['_id'] as String, data);
                    widget.onSnack('Actividad actualizada');
                  } else {
                    await widget.api.createActividad(data);
                    widget.onSnack('Actividad creada');
                  }
                  _load();
                } catch (e) {
                  widget.onSnack('Error: $e', error: true);
                }
              },
              child: Text(isEdit ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  Color _tipoColor(String tipo) {
    switch (tipo) {
      case 'Tarea':        return _blue;
      case 'Examen':       return _red;
      case 'Cuestionario': return _gold;
      case 'Proyecto':     return _purple;
      case 'Reunión':      return _green;
      default: return Colors.white54;
    }
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'Activa':      return _green;
      case 'Próxima':     return _gold;
      case 'Finalizada':  return Colors.white38;
      default: return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats
        if (_stats != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                _miniStat('Total',      _stats!['total']?.toString() ?? '0',      Colors.white60),
                _miniStat('Activas',    _stats!['activas']?.toString() ?? '0',    _green),
                _miniStat('Próximas',   _stats!['proximas']?.toString() ?? '0',   _gold),
                _miniStat('Finalizadas',_stats!['finalizadas']?.toString() ?? '0', Colors.white38),
              ],
            ),
          ),
        const SizedBox(height: 12),
        // Filtros + búsqueda
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(child: _searchBar('Buscar actividad...', _searchCtrl, (_) => _load())),
              const SizedBox(width: 8),
              _filterChip('Tipo:', _filterTipo, _tipos, (v) => setState(() { _filterTipo = v; _load(); })),
              const SizedBox(width: 8),
              _filterChip('Estado:', _filterEstado, _estados, (v) => setState(() { _filterEstado = v; _load(); })),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showForm(),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Nueva'),
                style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _gold))
              : _actividades.isEmpty
                  ? _emptyState('No hay actividades')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: _actividades.length,
                      itemBuilder: (ctx, i) {
                        final a = _actividades[i] as Map<String, dynamic>;
                        final tipo   = a['tipo'] as String? ?? 'Tarea';
                        final estado = a['estado'] as String? ?? 'Próxima';
                        final fecha  = a['fechaEntrega'] != null
                            ? DateFormat('dd MMM yyyy', 'es').format(DateTime.parse(a['fechaEntrega'] as String))
                            : '-';
                        final tc = _tipoColor(tipo);
                        final ec = _estadoColor(estado);
                        final materia = a['materiaId'];
                        final materiaNombre = materia is Map ? materia['nombre'] as String? ?? '' : '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: tc.withOpacity(0.15)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: tc.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.event_note_rounded, color: Colors.white70, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: tc.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                          child: Text(tipo, style: TextStyle(color: tc, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(color: ec.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                          child: Text(estado, style: TextStyle(color: ec, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(a['titulo'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 10, color: Colors.white.withOpacity(0.4)),
                                        const SizedBox(width: 4),
                                        Text(fecha, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                                        if (materiaNombre.isNotEmpty) ...[
                                          const SizedBox(width: 10),
                                          Icon(Icons.menu_book_rounded, size: 10, color: Colors.white.withOpacity(0.4)),
                                          const SizedBox(width: 4),
                                          Text(materiaNombre, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.edit_rounded, color: _blue, size: 18), onPressed: () => _showForm(a)),
                              IconButton(
                                icon: const Icon(Icons.delete_rounded, color: _red, size: 18),
                                onPressed: () async {
                                  try {
                                    await widget.api.deleteActividad(a['_id'] as String);
                                    widget.onSnack('Actividad eliminada');
                                    _load();
                                  } catch (e) {
                                    widget.onSnack('Error: $e', error: true);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
            Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MÓDULO 7: AGENDA
// ══════════════════════════════════════════════════════════════
class _AgendaModule extends StatefulWidget {
  final ApiService api;
  final void Function(String, {bool error}) onSnack;
  const _AgendaModule({required this.api, required this.onSnack});
  @override
  State<_AgendaModule> createState() => _AgendaModuleState();
}
class _AgendaModuleState extends State<_AgendaModule> {
  DateTime _focusedDay  = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  final List<Map<String, dynamic>> _events = [
    {'date': DateTime.now(), 'title': 'Reunión de padres', 'place': 'Aula Magna', 'time': '18:00', 'color': _purple},
    {'date': DateTime.now().add(const Duration(days: 2)), 'title': 'Entrega planificaciones', 'place': 'Secretaría', 'time': '10:00', 'color': _blue},
    {'date': DateTime.now().add(const Duration(days: 5)), 'title': 'Capacitación docente', 'place': 'Informática', 'time': '14:30', 'color': _green},
    {'date': DateTime.now().add(const Duration(days: 7)), 'title': 'Evaluación trimestral', 'place': 'Aulas', 'time': '08:00', 'color': _red},
    {'date': DateTime.now().add(const Duration(days: 10)), 'title': 'Consejo estudiantil', 'place': 'Auditorio', 'time': '16:00', 'color': _gold},
  ];

  List<Map<String, dynamic>> get _selectedEvents => _events
      .where((e) => _isSameDay(e['date'] as DateTime, _selectedDay))
      .toList();

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _hasEvent(DateTime day) => _events.any((e) => _isSameDay(e['date'] as DateTime, day));

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del calendario
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // Navegación mes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                      onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1)),
                    ),
                    Text(
                      DateFormat('MMMM yyyy', 'es').format(_focusedDay).toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                      onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Días de semana
                Row(
                  children: ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sa', 'Do']
                      .map((d) => Expanded(
                            child: Center(
                              child: Text(d, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
                // Grilla de días
                _buildCalendarGrid(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Eventos del día seleccionado
          _sectionTitle(
            'Eventos — ${DateFormat('d \'de\' MMMM', 'es').format(_selectedDay)}',
            Icons.event_rounded,
          ),
          const SizedBox(height: 10),
          if (_selectedEvents.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14)),
              child: Center(child: Text('Sin eventos este día',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13))),
            )
          else
            ..._selectedEvents.map((e) => _eventCard(e)),
          const SizedBox(height: 16),
          _sectionTitle('Próximos eventos', Icons.upcoming_rounded),
          const SizedBox(height: 10),
          ..._events.where((e) => (e['date'] as DateTime).isAfter(DateTime.now())).take(5).map((e) => _eventCard(e)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final daysInMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0).day;
    final startWeekday = firstDay.weekday; // 1=Lun, 7=Dom
    final blanks = startWeekday - 1;
    final total = blanks + daysInMonth;
    final rows  = (total / 7).ceil();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
      itemCount: rows * 7,
      itemBuilder: (_, idx) {
        final dayNum = idx - blanks + 1;
        if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox();
        final day = DateTime(_focusedDay.year, _focusedDay.month, dayNum);
        final isSelected = _isSameDay(day, _selectedDay);
        final isToday    = _isSameDay(day, DateTime.now());
        final hasEvent   = _hasEvent(day);
        return GestureDetector(
          onTap: () => setState(() => _selectedDay = day),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _navy : isToday ? _gold.withOpacity(0.2) : Colors.transparent,
              border: isToday && !isSelected ? Border.all(color: _gold, width: 1.5) : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(dayNum.toString(),
                    style: TextStyle(
                      color: isSelected ? Colors.white : isToday ? _gold : Colors.white70,
                      fontSize: 11,
                      fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                    )),
                if (hasEvent)
                  Positioned(
                    bottom: 3,
                    child: Container(width: 4, height: 4,
                        decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _eventCard(Map<String, dynamic> e) {
    final color = e['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                Text(DateFormat('d').format(e['date'] as DateTime),
                    style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
                Text(DateFormat('MMM', 'es').format(e['date'] as DateTime).toUpperCase(),
                    style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.place_rounded, size: 11, color: Colors.white.withOpacity(0.4)),
                    const SizedBox(width: 3),
                    Text(e['place'] as String, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(e['time'] as String, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MÓDULO 8: CALIFICACIONES
// ══════════════════════════════════════════════════════════════
class _CalificacionesModule extends StatefulWidget {
  final ApiService api;
  const _CalificacionesModule({required this.api});
  @override
  State<_CalificacionesModule> createState() => _CalificacionesModuleState();
}
class _CalificacionesModuleState extends State<_CalificacionesModule> {
  final _grades = [
    {'name': 'Luis Pérez',   'materia': 'Prog. Web',   'actividad': 'Tarea 1', 'nota': 95, 'obs': 'Excelente trabajo'},
    {'name': 'Ana Gómez',    'materia': 'Prog. Web',   'actividad': 'Tarea 1', 'nota': 88, 'obs': 'Revisar CSS'},
    {'name': 'Pedro Ruiz',   'materia': 'Bases Datos', 'actividad': 'Examen 1','nota': 72, 'obs': 'Mejorar consultas'},
    {'name': 'Sofía Torres', 'materia': 'Prog. Web',   'actividad': 'Tarea 1', 'nota': 100,'obs': 'Perfecto'},
    {'name': 'Carlos Mora',  'materia': 'Redes',       'actividad': 'Lab 1',   'nota': 65, 'obs': 'Practicar más'},
    {'name': 'María López',  'materia': 'Bases Datos', 'actividad': 'Examen 1','nota': 90, 'obs': 'Muy bueno'},
    {'name': 'José Vargas',  'materia': 'Redes',       'actividad': 'Lab 1',   'nota': 55, 'obs': 'Refuerzo necesario'},
    {'name': 'Carmen Díaz',  'materia': 'Prog. Web',   'actividad': 'Tarea 2', 'nota': 78, 'obs': 'Bien'},
  ];
  String _filterMateria = 'Todas';
  final _materias = ['Todas', 'Prog. Web', 'Bases Datos', 'Redes'];

  List<Map<String, dynamic>> get _filtered => _filterMateria == 'Todas'
      ? _grades
      : _grades.where((g) => g['materia'] == _filterMateria).toList();

  double get _promedio {
    if (_filtered.isEmpty) return 0;
    return _filtered.map((g) => g['nota'] as int).reduce((a, b) => a + b) / _filtered.length;
  }

  Color _notaColor(int nota) {
    if (nota >= 90) return _green;
    if (nota >= 70) return _gold;
    return _red;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Resumen
          Row(
            children: [
              _gradeStatCard('Promedio general', _promedio.toStringAsFixed(1), Icons.analytics_rounded, _blue),
              const SizedBox(width: 12),
              _gradeStatCard('Aprobados (≥70)',
                  _filtered.where((g) => (g['nota'] as int) >= 70).length.toString(),
                  Icons.check_circle_rounded, _green),
              const SizedBox(width: 12),
              _gradeStatCard('Reprobados (<70)',
                  _filtered.where((g) => (g['nota'] as int) < 70).length.toString(),
                  Icons.cancel_rounded, _red),
            ],
          ),
          const SizedBox(height: 16),
          // Barra de distribución
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Distribución de calificaciones',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 14),
                _barRow('Sobresaliente (90-100)',
                    _filtered.where((g) => (g['nota'] as int) >= 90).length,
                    _filtered.length, _green),
                _barRow('Bueno (70-89)',
                    _filtered.where((g) => (g['nota'] as int) >= 70 && (g['nota'] as int) < 90).length,
                    _filtered.length, _gold),
                _barRow('En riesgo (<70)',
                    _filtered.where((g) => (g['nota'] as int) < 70).length,
                    _filtered.length, _red),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Filtro + tabla
          Row(
            children: [
              const Text('Materia:', style: TextStyle(color: Colors.white60, fontSize: 12)),
              const SizedBox(width: 10),
              ..._materias.map((m) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(m, style: TextStyle(
                    color: _filterMateria == m ? Colors.white : Colors.white60,
                    fontSize: 11,
                  )),
                  selected: _filterMateria == m,
                  selectedColor: _navy,
                  backgroundColor: _surface,
                  onSelected: (_) => setState(() => _filterMateria = m),
                  side: BorderSide(color: _filterMateria == m ? _navy : Colors.white.withOpacity(0.1)),
                ),
              )),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                // Encabezado tabla
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: ['Estudiante', 'Materia', 'Actividad', 'Nota', 'Observación']
                        .asMap()
                        .entries
                        .map((e) => Expanded(
                              flex: e.key == 4 ? 2 : 1,
                              child: Text(e.value,
                                  style: TextStyle(color: Colors.white.withOpacity(0.4),
                                      fontSize: 10, fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                  ),
                ),
                ..._filtered.asMap().entries.map((entry) {
                  final g = entry.value;
                  final nota  = g['nota'] as int;
                  final color = _notaColor(nota);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.03))),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(g['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 11))),
                        Expanded(child: Text(g['materia'] as String, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11))),
                        Expanded(child: Text(g['actividad'] as String, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11))),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('$nota / 100', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        Expanded(flex: 2, child: Text(g['obs'] as String, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w900)),
            Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _barRow(String label, int count, int total, Color color) {
    final fraction = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 130, child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: color.withOpacity(0.1),
                color: color,
                minHeight: 10,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$count', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MÓDULO 9: REPORTES
// ══════════════════════════════════════════════════════════════
class _ReportesModule extends StatefulWidget {
  final ApiService api;
  const _ReportesModule({required this.api});
  @override
  State<_ReportesModule> createState() => _ReportesModuleState();
}
class _ReportesModuleState extends State<_ReportesModule> {
  String _periodo = 'Bimestre 1';
  final _periodos = ['Bimestre 1', 'Bimestre 2', 'Bimestre 3', 'Bimestre 4'];

  final _rendimiento = [
    {'label': 'Prog. Web',   'valor': 0.87, 'color': _blue},
    {'label': 'Bases Datos', 'valor': 0.74, 'color': _green},
    {'label': 'Redes',       'valor': 0.62, 'color': _gold},
    {'label': 'S.O.',        'valor': 0.91, 'color': _purple},
    {'label': 'Inglés',      'valor': 0.78, 'color': _red},
  ];

  final _actEstado = [
    {'label': 'Completadas', 'valor': 100, 'color': _green},
    {'label': 'En progreso', 'valor': 80,  'color': _gold},
    {'label': 'Pendientes',  'valor': 40,  'color': _red},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.08))),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _periodo,
                    dropdownColor: _surface,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    onChanged: (v) => setState(() => _periodo = v!),
                    items: _periodos.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: const Text('Exportar PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Rendimiento por materia
          _sectionTitle('Rendimiento general por materia', Icons.bar_chart_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: _rendimiento.map((r) {
                final color = r['color'] as Color;
                final val   = r['valor'] as double;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(
                    children: [
                      SizedBox(width: 80, child: Text(r['label'] as String, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11))),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(height: 20, decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(6))),
                            FractionallySizedBox(
                              widthFactor: val,
                              child: Container(
                                height: 20,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('${(val * 100).toInt()}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          // Actividades por estado
          _sectionTitle('Actividades por estado — $_periodo', Icons.donut_large_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                // Gráfico de barras
                Expanded(
                  child: SizedBox(
                    height: 120,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: _actEstado.map((a) {
                        final color = a['color'] as Color;
                        final val   = a['valor'] as int;
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('$val', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Container(
                              width: 36,
                              height: val.toDouble(),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                                  colors: [color, color.withOpacity(0.5)],
                                ),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(a['label'] as String, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9), textAlign: TextAlign.center),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Leyenda
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _actEstado.map((a) {
                    final color = a['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('${a['label']}: ${a['valor']}', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Resumen ejecutivo
          _sectionTitle('Resumen ejecutivo', Icons.summarize_rounded),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                _resumeRow('Promedio institucional', '81.2 / 100', _blue),
                _resumeRow('Tasa de aprobación',     '87%',        _green),
                _resumeRow('Actividades completadas','220 / 256',  _gold),
                _resumeRow('Asistencia promedio',    '93.4%',      _purple),
                _resumeRow('Docentes activos',        '28',         Colors.white70),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resumeRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(width: 3, height: 16, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12))),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// MÓDULO 10: CONFIGURACIÓN
// ══════════════════════════════════════════════════════════════
class _ConfiguracionModule extends StatefulWidget {
  final void Function(String, {bool error}) onSnack;
  const _ConfiguracionModule({required this.onSnack});
  @override
  State<_ConfiguracionModule> createState() => _ConfiguracionModuleState();
}
class _ConfiguracionModuleState extends State<_ConfiguracionModule> {
  final _nombreCtrl  = TextEditingController(text: 'Colegio Germán Busch "A"');
  final _annoCtrl    = TextEditingController(text: '2025');
  String _idioma     = 'Español';
  String _zona       = 'America/La_Paz (BOT -4)';
  bool _notifEmail   = true;
  bool _notifPush    = true;
  bool _modoMantto   = false;
  String _tab        = 'General';

  final _tabs = ['General', 'Seguridad', 'Notificaciones', 'Sistema'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          Container(
            decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.all(4),
            child: Row(
              children: _tabs.map((t) {
                final isSelected = _tab == t;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? _navy : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(t,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          if (_tab == 'General')   _buildGeneral()
          else if (_tab == 'Seguridad') _buildSeguridad()
          else if (_tab == 'Notificaciones') _buildNotificaciones()
          else _buildSistema(),
        ],
      ),
    );
  }

  Widget _buildGeneral() => Column(
    children: [
      _configCard('Información del sistema', Icons.info_outline_rounded, [
        _fieldRow('Nombre del sistema', _nombreCtrl),
        const SizedBox(height: 12),
        _fieldRow('Año académico', _annoCtrl),
        const SizedBox(height: 12),
        _dropRowConfig('Idioma', _idioma, ['Español', 'English'],
            (v) => setState(() => _idioma = v!)),
        const SizedBox(height: 12),
        _dropRowConfig('Zona horaria', _zona,
            ['America/La_Paz (BOT -4)', 'America/Bogota (COT -5)', 'America/Lima (PET -5)'],
            (v) => setState(() => _zona = v!)),
      ]),
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: () => widget.onSnack('Configuración guardada'),
          icon: const Icon(Icons.save_rounded, size: 16),
          label: const Text('Guardar cambios'),
          style: ElevatedButton.styleFrom(backgroundColor: _navy, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
        ),
      ),
    ],
  );

  Widget _buildSeguridad() => Column(
    children: [
      _configCard('Seguridad de acceso', Icons.security_rounded, [
        _switchRow('Autenticación de dos factores', false, (_) {}),
        _switchRow('Registro de actividades', true, (_) {}),
        _switchRow('Sesiones múltiples', false, (_) {}),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _red.withOpacity(0.08), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _red.withOpacity(0.2))),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _red, size: 18),
              const SizedBox(width: 10),
              const Expanded(child: Text('Las contraseñas se encriptan con bcrypt (10 rondas)',
                  style: TextStyle(color: Colors.white70, fontSize: 11))),
            ],
          ),
        ),
      ]),
    ],
  );

  Widget _buildNotificaciones() => Column(
    children: [
      _configCard('Notificaciones push', Icons.notifications_rounded, [
        _switchRow('Notificaciones por email', _notifEmail, (v) => setState(() => _notifEmail = v)),
        _switchRow('Notificaciones push (FCM)', _notifPush, (v) => setState(() => _notifPush = v)),
        _switchRow('Alertas de calificaciones', true, (_) {}),
        _switchRow('Recordatorios de actividades', true, (_) {}),
        _switchRow('Alertas de entregas tardías', false, (_) {}),
      ]),
    ],
  );

  Widget _buildSistema() => Column(
    children: [
      _configCard('Estado del sistema', Icons.settings_applications_rounded, [
        _switchRow('Modo mantenimiento', _modoMantto, (v) => setState(() => _modoMantto = v)),
        _infoRow('Versión del backend', '2.0.0'),
        _infoRow('Base de datos', 'MongoDB Atlas'),
        _infoRow('Servicio OCR', 'FastAPI + Tesseract'),
        _infoRow('Notificaciones', 'Firebase Cloud Messaging'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => widget.onSnack('Caché limpiada'),
                icon: const Icon(Icons.cleaning_services_rounded, size: 16, color: Colors.white60),
                label: const Text('Limpiar caché', style: TextStyle(color: Colors.white60, fontSize: 12)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white.withOpacity(0.1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => widget.onSnack('Diagnóstico ejecutado'),
                icon: const Icon(Icons.health_and_safety_rounded, size: 16),
                label: const Text('Diagnóstico', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10), elevation: 0),
              ),
            ),
          ],
        ),
      ]),
    ],
  );

  Widget _configCard(String title, IconData icon, List<Widget> children) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: _gold, size: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
        const SizedBox(height: 16),
        const Divider(color: Colors.white10, height: 1),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );

  Widget _fieldRow(String label, TextEditingController ctrl) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _navy)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ],
  );

  Widget _dropRowConfig(String label, String value, List<String> items, ValueChanged<String?> onChanged) => Row(
    children: [
      Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: _card, borderRadius: BorderRadius.circular(10)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            dropdownColor: _surface,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            onChanged: onChanged,
            items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
          ),
        ),
      ),
    ],
  );

  Widget _switchRow(String label, bool value, ValueChanged<bool> onChanged) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12))),
        Switch(value: value, onChanged: onChanged, activeColor: _gold, inactiveThumbColor: Colors.white38),
      ],
    ),
  );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: _navy.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
          child: Text(value, style: const TextStyle(color: _blue, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

// ══════════════════════════════════════════════════════════════
// HELPERS GLOBALES
// ══════════════════════════════════════════════════════════════

Widget _sectionTitle(String title, IconData icon) => Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    Icon(icon, color: _gold, size: 16),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
  ],
);

Widget _emptyState(String msg) => Center(
  child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.inbox_rounded, color: Colors.white.withOpacity(0.15), size: 64),
      const SizedBox(height: 12),
      Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
    ],
  ),
);

Widget _inputField(String hint, TextEditingController ctrl, IconData icon, {bool obscure = false}) {
  return TextField(
    controller: ctrl,
    obscureText: obscure,
    style: const TextStyle(color: Colors.white, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.white38, size: 18),
      filled: true,
      fillColor: const Color(0xFF0A0E24),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _navy)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
  );
}

Widget _searchBar(String hint, TextEditingController ctrl, ValueChanged<String> onChanged) {
  return Container(
    height: 42,
    decoration: BoxDecoration(
      color: _surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.06)),
    ),
    child: TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.3), size: 18),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onChanged: onChanged,
    ),
  );
}

Widget _dropdownField(String label, String value, List<String> items,
    ValueChanged<String?> onChanged, IconData icon) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xFF0A0E24),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              dropdownColor: _surface,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              hint: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3))),
              isExpanded: true,
              onChanged: onChanged,
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _filterChip(String prefix, String current, List<String> options, ValueChanged<String> onChanged) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08))),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: current,
        dropdownColor: _surface,
        style: const TextStyle(color: Colors.white, fontSize: 11),
        onChanged: (v) => onChanged(v!),
        items: options.map((o) => DropdownMenuItem(value: o, child: Text('$prefix $o'))).toList(),
      ),
    ),
  );
}
