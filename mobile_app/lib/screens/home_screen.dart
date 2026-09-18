import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart'; // FCM push notifications

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _allAgendaItems = [];
  List<dynamic> _filteredItems = [];
  bool _isLoading = true;
  bool _isInit = false;
  String? _userId;
  String? _userName;
  String? _userRole;     // 'student', 'teacher' o 'admin'
  String? _userMaterias; // Materias asignadas (solo docentes)
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;

  late AnimationController _headerController;
  late AnimationController _fabController;
  late AnimationController _listController;
  late AnimationController _shimmerController;
  late AnimationController _calendarController;

  late Animation<double> _headerOpacity;
  late Animation<Offset> _headerSlide;
  late Animation<double> _fabScale;
  late Animation<double> _shimmer;
  late Animation<double> _calendarOpacity;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _headerController, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic),
    );

    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _fabScale = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _fabController, curve: Curves.easeInOut),
    );

    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _shimmer = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _calendarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _calendarOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _calendarController, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final user = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (user != null && user['_id'] != null) {
        _userId      = user['_id'];
        _userName    = user['name']     ?? 'Usuario';
        _userRole    = user['role']     ?? 'student'; // Leer el rol del usuario
        _userMaterias = user['materias'] as String?;  // Materias asignadas al docente
      } else {
        _userId   = 'guest_user';
        _userName = 'Invitado';
        _userRole = 'student';
      }
      _headerController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _calendarController.forward();
      });
      _fetchAgenda();

      // Registrar token FCM del dispositivo en el backend
      // para que el servidor pueda enviar notificaciones a este usuario
      _registerFcmToken();

      _isInit = true;
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _fabController.dispose();
    _listController.dispose();
    _shimmerController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  /// Registra el token FCM del dispositivo en el backend.
  /// Se llama una vez al abrir HomeScreen (después del login).
  Future<void> _registerFcmToken() async {
    if (_userId == null) return;
    final token = NotificationService().fcmToken;
    if (token == null || token.isEmpty) return;
    await _apiService.saveFcmToken(_userId!, token);
    debugPrint('📱 FCM Token enviado al backend para userId: $_userId');

    // Suscribir al topic "estudiantes" para recibir avisos generales
    await NotificationService().subscribeToTopic('estudiantes');
  }

  Future<void> _fetchAgenda() async {
    if (_userId == null) return;
    setState(() => _isLoading = true);
    try {
      final items = await _apiService.getAgenda(_userId!);
      setState(() {
        _allAgendaItems = items;
        _filterItemsByDate(_selectedDay!);
        _isLoading = false;
      });
      _listController.forward(from: 0);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar agenda: $e'),
            backgroundColor: const Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  void _filterItemsByDate(DateTime date) {
    setState(() {
      _filteredItems = _allAgendaItems.where((item) {
        final itemDate = DateTime.parse(item['date']).toLocal();
        return isSameDay(itemDate, date);
      }).toList();
    });
    _listController.forward(from: 0);
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️ Buenos días';
    if (hour < 18) return '🌤️ Buenas tardes';
    return '🌙 Buenas noches';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: Column(
        children: [
          _buildAnimatedHeader(),
          _buildCalendarSection(),
          const SizedBox(height: 4),
          _buildSectionTitle(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _buildAnimatedFAB(),
    );
  }

  Widget _buildAnimatedHeader() {
    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, _) {
        return SlideTransition(
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
                      // Avatar
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFC107).withOpacity(0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            (_userName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF0D1B4E),
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _userName ?? 'Usuario',
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
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: const Color(0xFFFFC107).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(Icons.rocket_launch_rounded,
                              color: Color(0xFFFFC107), size: 22),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/universe',
                            arguments: {'_id': _userId, 'name': _userName},
                          );
                        },
                      ),
                      // Botón Panel Docente (visible solo si role == 'teacher')
                      if (_userRole == 'teacher')
                        IconButton(
                          tooltip: 'Panel Docente',
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6F00), Color(0xFFFFC107)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFC107).withOpacity(0.4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.school_rounded,
                                color: Color(0xFF0D1B4E), size: 22),
                          ),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/teacher-dashboard',
                              arguments: {
                                '_id':      _userId,
                                'name':     _userName,
                                'materias': _userMaterias, // Materias asignadas al docente
                              },
                            );
                          },
                        ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: const Icon(Icons.notifications_none_rounded,
                              color: Colors.white, size: 22),
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.1),
                          ),
                          child: const Icon(Icons.logout_rounded,
                              color: Colors.white, size: 22),
                        ),
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context, '/login', (r) => false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarSection() {
    return AnimatedBuilder(
      animation: _calendarController,
      builder: (ctx, _) => FadeTransition(
        opacity: _calendarOpacity,
        child: Container(
          color: Colors.white,
          child: TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2027, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            locale: 'es_ES',
            eventLoader: _getEventsForDay,
            calendarBuilders: CalendarBuilders(
              markerBuilder: (ctx, date, events) {
                if (events.isNotEmpty) {
                  return Positioned(
                    bottom: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: events
                          .take(3)
                          .map((e) => Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getColor(
                                      (e as Map<String, dynamic>)['type']),
                                ),
                              ))
                          .toList(),
                    ),
                  );
                }
                return null;
              },
            ),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _filterItemsByDate(selectedDay);
            },
            onFormatChanged: (format) => setState(() => _calendarFormat = format),
            headerStyle: const HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              titleTextStyle: TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
              formatButtonDecoration: BoxDecoration(
                color: Color(0xFF1A237E),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              formatButtonTextStyle: TextStyle(color: Colors.white, fontSize: 12),
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Color(0xFFFFC107), shape: BoxShape.circle),
              selectedDecoration: BoxDecoration(color: Color(0xFF1A237E), shape: BoxShape.circle),
              weekendTextStyle: TextStyle(color: Color(0xFFE53935)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle() {
    final dateStr = _selectedDay != null
        ? DateFormat('EEEE, d MMM', 'es_ES').format(_selectedDay!)
        : '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
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
            dateStr,
            style: const TextStyle(
              color: Color(0xFF1A237E),
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const Spacer(),
          if (_filteredItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color(0xFF1A237E).withOpacity(0.1),
              ),
              child: Text(
                '${_filteredItems.length} evento${_filteredItems.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: Color(0xFF1A237E),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildShimmerList();
    if (_filteredItems.isEmpty) return _buildEmptyState();
    return _buildAnimatedList();
  }

  Widget _buildShimmerList() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (ctx, _) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 3,
          itemBuilder: (ctx, i) => _buildShimmerCard(_shimmer.value),
        );
      },
    );
  }

  Widget _buildShimmerCard(double shimmerValue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment(shimmerValue - 1, 0),
          end: Alignment(shimmerValue, 0),
          colors: [
            Colors.grey[200]!,
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return AnimatedBuilder(
      animation: _listController,
      builder: (ctx, _) => FadeTransition(
        opacity: _listController,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1A237E).withOpacity(0.07),
                ),
                child: const Icon(
                  Icons.event_available_rounded,
                  size: 52,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Sin actividades',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A237E),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '¡Aprovecha para descansar!',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/camera',
                      arguments: {'_id': _userId});
                  _fetchAgenda();
                },
                icon: const Icon(Icons.document_scanner_rounded, size: 18),
                label: const Text('Escanear Agenda'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedList() {
    return AnimatedBuilder(
      animation: _listController,
      builder: (ctx, _) {
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: _filteredItems.length,
          itemBuilder: (ctx, index) {
            final progress = (_listController.value - index * 0.12).clamp(0.0, 1.0);
            final curved = Curves.easeOutCubic.transform(progress);
            // ── Efecto de entrada 3D: la tarjeta cae girando sobre X ──
            final flipX = (1 - curved) * -0.45; // radianes de rotación
            return Opacity(
              opacity: curved,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspectiva
                  ..rotateX(flipX)
                  ..translate(0.0, (1 - curved) * 40.0),
                child: _build3DAgendaCard(_filteredItems[index], index),
              ),
            );
          },
        );
      },
    );
  }

  // Mapa para controlar qué tarjeta está siendo presionada
  final Map<int, bool> _cardPressed = {};

  Widget _build3DAgendaCard(dynamic item, int index) {
    final bool hasImage = item['imageUrl'] != null && item['imageUrl'].toString().isNotEmpty;
    final Color typeColor = _getColor(item['type']);
    final IconData typeIcon = _getIcon(item['type']);
    final String typeLabel = _getTypeLabel(item['type']);
    final bool isPressed = _cardPressed[index] ?? false;

    return GestureDetector(
      onTapDown: (_) => setState(() => _cardPressed[index] = true),
      onTapUp: (_) => setState(() => _cardPressed[index] = false),
      onTapCancel: () => setState(() => _cardPressed[index] = false),
      onTap: () => _openEditScreen(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 14),
        // Escala sutil al presionar (efecto profundidad)
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
              ? [
                  BoxShadow(
                    color: typeColor.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: typeColor.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                child: Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.memory(
                        base64Decode(item['imageUrl']),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _buildTypeBadge(typeLabel, typeColor, typeIcon),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (!hasImage) _buildTypeBadge(typeLabel, typeColor, typeIcon),
                      if (!hasImage) const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item['title'] ?? 'Sin título',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: Color(0xFF0D1B4E),
                          ),
                        ),
                      ),
                      if (item['is_completed'] == true) ...[
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.withOpacity(0.1),
                          ),
                          child: const Icon(Icons.check_circle_rounded,
                              color: Colors.green, size: 22),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey, size: 20),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                        splashRadius: 20,
                        tooltip: 'Editar Evento',
                        onPressed: () => _openEditScreen(item),
                      ),
                    ],
                  ),
                  if (item['description'] != null &&
                      item['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      item['description'],
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13, height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.calendar_today_rounded,
                        DateFormat('EEE dd MMM', 'es_ES')
                            .format(DateTime.parse(item['date'])),
                        const Color(0xFF1A237E).withOpacity(0.08),
                        const Color(0xFF1A237E),
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.access_time_rounded,
                        DateFormat('HH:mm')
                            .format(DateTime.parse(item['date'])),
                        const Color(0xFFFFC107).withOpacity(0.15),
                        const Color(0xFF795548),
                      ),
                    ],
                  ),
                  // ── Botón Entregar PDF (solo tareas de tipo homework sin completar) ──
                  if (item['type'] == 'homework' && item['is_completed'] != true) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/submit-task',
                          arguments: {
                            'taskId':      item['_id']?.toString() ?? '',
                            'taskTitle':   item['title'] ?? 'Tarea',
                            'taskSubject': item['subject'] ?? '',
                            'userId':      _userId,
                          },
                        );
                        // Si se entregó exitosamente, refrescar la lista
                        if (result == true) _fetchAgenda();
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF43A047).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.upload_file_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Entregar PDF',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
                color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAnimatedFAB() {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (ctx, _) {
        // El FAB flota y tiene sombra dinámica (efecto de elevación 3D)
        final elevation = _fabScale.value;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..scale(elevation)
            ..translate(0.0, (1 - elevation) * -8.0), // sube al expandirse
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD54F), Color(0xFFFF8F00)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC107)
                      .withOpacity(0.35 + (elevation - 1) * 1.5),
                  blurRadius: 20 + (elevation - 1) * 60,
                  offset: Offset(0, 6 + (elevation - 1) * 20),
                ),
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () async {
                  await Navigator.pushNamed(
                    context,
                    '/camera',
                    arguments: {'_id': _userId},
                  );
                  _fetchAgenda();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.document_scanner_rounded,
                          color: Color(0xFF0D1B4E), size: 22),
                      SizedBox(width: 10),
                      Text(
                        'ESCANEAR',
                        style: TextStyle(
                          color: Color(0xFF0D1B4E),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    return _allAgendaItems.where((item) {
      final itemDate = DateTime.parse(item['date']).toLocal();
      return isSameDay(itemDate, day);
    }).toList();
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'homework': return 'TAREA';
      case 'exam': return 'EXAMEN';
      case 'reminder': return 'RECORDATORIO';
      default: return 'EVENTO';
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'homework': return const Color(0xFF1976D2);
      case 'exam': return const Color(0xFFE53935);
      case 'reminder': return const Color(0xFFFF8F00);
      default: return const Color(0xFF1A237E);
    }
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'homework': return Icons.menu_book_rounded;
      case 'exam': return Icons.assignment_late_rounded;
      case 'reminder': return Icons.notifications_active_rounded;
      default: return Icons.push_pin_rounded;
    }
  }

  Future<void> _openEditScreen(dynamic item) async {
    final result = await Navigator.pushNamed(
      context,
      '/edit-agenda',
      arguments: item,
    );
    if (result == true) {
      _fetchAgenda();
    }
  }
}
