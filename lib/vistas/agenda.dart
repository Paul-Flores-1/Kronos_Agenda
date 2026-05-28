import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/evento_model.dart';
import 'menu.dart';   
import 'anadir.dart';

class AgendaScreen extends StatefulWidget {
  const AgendaScreen({super.key});

  @override
  State<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends State<AgendaScreen> {
  final AuthService _authService = AuthService();
  Timer? _timer;
  late Stream<List<Evento>> _misEventosStream;

  @override
  void initState() {
    super.initState();
    _misEventosStream = _authService.getEvents();
    // Actualiza la UI cada 30 seg para mantener la referencia de "Ahora"
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateFormat = DateFormat('d MMM yyyy', 'es_ES');
    final timeFormat = DateFormat('h:mm a', 'es_ES');

    // Definimos colores de texto dinámicos para usar en toda la pantalla
    final mainTextColor = theme.textTheme.titleLarge?.color;
    final subTextColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7);

    return Scaffold(
      body: Column(
        children: [
          // CABECERA
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // BOTÓN MENÚ
                      Container(
                        decoration: BoxDecoration(
                          color: isDark 
                              ? Colors.white.withValues(alpha: 0.1) 
                              : Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const MenuScreen()),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.menu_rounded, 
                                color: mainTextColor, 
                                size: 24
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // SALUDO
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          String saludo = "Agenda";
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            final nombreCompleto = data['nombre'] ?? "";
                            if (nombreCompleto.isNotEmpty) {
                              final primerNombre = nombreCompleto.split(' ')[0];
                              saludo = "¡Hola, $primerNombre!";
                            }
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                saludo,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormat('EEEE, d MMMM', 'es_ES').format(DateTime.now()),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: subTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),

          // LISTA DE EVENTOS
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color, 
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: StreamBuilder<List<Evento>>(
                  stream: _misEventosStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                       return const Center(child: Text("Sincronizando...", style: TextStyle(color: Colors.grey)));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF5E81AC)));
                    }
                    
                    final now = DateTime.now();
                    var eventos = snapshot.data ?? [];
                    
                    // Filtro de eventos pasados
                    eventos = eventos.where((e) {
                       if (e.todoElDia) {
                         final finDia = DateTime(e.fechaFin.year, e.fechaFin.month, e.fechaFin.day, 23, 59, 59);
                         return finDia.isAfter(now);
                       }
                       return e.fechaFin.isAfter(now);
                    }).toList();

                    eventos.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));

                    if (eventos.isEmpty) {
                      return _buildEmptyState(context, isDark, mainTextColor, subTextColor);
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      itemCount: eventos.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final evento = eventos[index];
                        return _buildEventItem(context, evento, dateFormat, timeFormat);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      
      // BOTÓN FLOTANTE
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 20, bottom: 15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF99C2FF).withValues(alpha: 0.4), 
                blurRadius: 12,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: FloatingActionButton(
            backgroundColor: const Color(0xFF99C2FF),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.add_rounded, size: 32, color: Color(0xFF1E2D3A)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddEventScreen()),
              );
            },
          ),
        ),
      ),
    );
  }

  // WIDGET DE EVENTO INDIVIDUAL (MODIFICADO PARA CUMPLEAÑOS Y CONFIRMACIÓN)
  Widget _buildEventItem(BuildContext context, Evento evento, DateFormat dateFormat, DateFormat timeFormat) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    IconData iconData = Icons.event;
    Color iconColor = Colors.grey;
    Color bgColor = Colors.grey.shade50;
    
    // Lógica de colores adaptada incluyendo CUMPLEAÑOS
    switch(evento.tipo) {
      case TipoEvento.muyEspecial: 
        iconData = Icons.star_rounded; 
        iconColor = Colors.amber.shade600; 
        bgColor = isDark ? Colors.amber.withValues(alpha: 0.15) : Colors.amber.shade50;
        break;
      case TipoEvento.cumpleanos: // Nuevo caso
        iconData = Icons.cake_rounded;
        iconColor = Colors.pink.shade300;
        bgColor = isDark ? Colors.pink.withValues(alpha: 0.15) : Colors.pink.shade50;
        break;
      case TipoEvento.especial:
        iconData = Icons.people_alt_rounded; 
        iconColor = Colors.purple.shade400; 
        bgColor = isDark ? Colors.purple.withValues(alpha: 0.15) : Colors.purple.shade50;
        break;
      case TipoEvento.cotidiano: 
        iconData = Icons.work_outline_rounded;
        iconColor = const Color(0xFF5E81AC); 
        bgColor = const Color(0xFF5E81AC).withValues(alpha: 0.1);
        break;
      case TipoEvento.recordatorio:
        iconData = Icons.notifications_active_rounded;
        iconColor = Colors.orange.shade600; 
        bgColor = isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50;
        break;
    }

    return Dismissible(
      key: Key(evento.id),
      direction: DismissDirection.startToEnd,
      // CONFIRMACIÓN DE BORRADO ANTES DE ELIMINAR
      confirmDismiss: (direction) async {
        return await _confirmarEliminar(context, evento);
      },
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade400, Colors.red.shade600],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        _authService.deleteEvent(evento.id);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color, 
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100, 
            width: 1.5
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(iconData, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5E81AC).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getDateLabel(evento.fechaInicio),
                          style: const TextStyle(
                            color: Color(0xFF5E81AC),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    evento.titulo,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color, 
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        evento.todoElDia ? Icons.calendar_today_rounded : Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        evento.todoElDia ? 'Todo el día' : timeFormat.format(evento.fechaInicio),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Botón de opciones
            Container(
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : const Color(0xFF5E81AC).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: PopupMenuButton<String>(
                color: theme.cardTheme.color,
                icon: Icon(
                  Icons.more_vert_rounded, 
                  size: 20, 
                  color: isDark 
                      ? Colors.white70 
                      : const Color(0xFF5E81AC).withValues(alpha: 0.8),
                ),
                padding: EdgeInsets.zero,
                offset: const Offset(0, 40),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  if (value == 'editar') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEventScreen(eventoParaEditar: evento),
                      ),
                    );
                  } else if (value == 'detalles') {
                    _mostrarDetalles(context, evento);
                  } else if (value == 'eliminar') {
                    _confirmarEliminar(context, evento);
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'detalles',
                    height: 48,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5E81AC).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded, 
                            color: Color(0xFF5E81AC), 
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Ver detalles',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<String>(
                    value: 'editar',
                    height: 48,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_outlined, 
                            color: Colors.blue, 
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Editar',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ESTADO VACÍO
  Widget _buildEmptyState(BuildContext context, bool isDark, Color? mainTextColor, Color? subTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.05) 
                    : const Color(0xFFA5BBC3).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_rounded, 
                size: 64, 
                color: isDark 
                    ? Colors.white.withValues(alpha: 0.2) 
                    : const Color(0xFFA5BBC3).withValues(alpha: 0.5)
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Tu agenda está al día",
              style: TextStyle(
                color: mainTextColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "No tienes eventos pendientes.\n¡Disfruta tu tiempo!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subTextColor,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // MODAL DE DETALLES
  void _mostrarDetalles(BuildContext context, Evento evento) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.cardTheme.color, 
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              evento.titulo,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 16),
            _detalleRow(
              context,
              Icons.access_time_rounded, 
              evento.todoElDia 
                ? 'Todo el día' 
                : '${DateFormat('h:mm a').format(evento.fechaInicio)} - ${DateFormat('h:mm a').format(evento.fechaFin)}',
            ),
            const SizedBox(height: 12),
            _detalleRow(
              context,
              Icons.calendar_today_rounded,
              DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(evento.fechaInicio),
            ),
            if (evento.descripcion.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              const Text(
                'Descripción:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                evento.descripcion,
                style: TextStyle(
                  fontSize: 15,
                  color: theme.textTheme.bodyLarge?.color,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detalleRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF5E81AC)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }

  // DIÁLOGO DE ELIMINAR (AHORA RETORNA BOOL PARA EL DISMISSIBLE)
  Future<bool> _confirmarEliminar(BuildContext context, Evento evento) async {
    final theme = Theme.of(context);
    bool confirmacion = false;
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.dialogTheme.backgroundColor, 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('¿Eliminar evento?'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${evento.titulo}"?',
          style: theme.dialogTheme.contentTextStyle ?? const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              confirmacion = true;
              Navigator.pop(ctx, true);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 20),
                      SizedBox(width: 12),
                      Text('Evento eliminado'),
                    ],
                  ),
                  backgroundColor: theme.brightness == Brightness.dark 
                      ? const Color(0xFF2C3E50) 
                      : const Color(0xFF1E2D3A),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return confirmacion;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(date.year, date.month, date.day);
    final difference = eventDate.difference(today).inDays;

    if (difference == 0) return 'HOY';
    if (difference == 1) return 'MAÑANA';
    if (difference > 1 && difference < 7) {
      return DateFormat('EEEE', 'es_ES').format(date).toUpperCase();
    }
    return DateFormat('d MMM', 'es_ES').format(date).toUpperCase();
  }
}