import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/evento_model.dart';
import 'anadir.dart'; 
import 'menu.dart';   

class MesScreen extends StatefulWidget {
  const MesScreen({super.key});

  @override
  State<MesScreen> createState() => _MesScreenState();
}

class _MesScreenState extends State<MesScreen> {
  final AuthService _authService = AuthService();
  
  DateTime _focusedDate = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  void _previousMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Variables de tema y fecha
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final daysInMonth = _getDaysInMonth(_focusedDate);
    final monthName = DateFormat('MMMM yyyy', 'es_ES').format(_focusedDate);
    final monthTitle = monthName[0].toUpperCase() + monthName.substring(1);
    final firstDayOfWeek = DateTime(_focusedDate.year, _focusedDate.month, 1).weekday;

    // Colores dinámicos para textos e iconos
    final mainTextColor = theme.textTheme.titleLarge?.color;
    final bodyTextColor = theme.textTheme.bodyLarge?.color;

    return Scaffold(
      // [CAMBIO 1] Eliminamos backgroundColor fijo para usar el del tema (app_theme.dart)
      
      body: Column(
        children: [
          // CABECERA
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Atrás
                  Container(
                    decoration: BoxDecoration(
                      // Fondo del botón adaptado
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.arrow_back_ios_new, 
                            // Icono claro en modo oscuro
                            color: mainTextColor, 
                            size: 20
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  Text(
                    "Calendario",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: mainTextColor,
                      letterSpacing: -0.5,
                    ),
                  ),

                  // Botón Menú
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
                ],
              ),
            ),
          ),

          // TARJETA PRINCIPAL (CALENDARIO)
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                // [CAMBIO 2] Color de fondo de la tarjeta desde el tema
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: StreamBuilder<List<Evento>>(
                  stream: _authService.getEvents(),
                  builder: (context, snapshot) {
                    List<Evento> eventosDelMes = [];

                    if (snapshot.hasData) {
                      eventosDelMes = snapshot.data!.where((e) {
                        return e.fechaInicio.month == _focusedDate.month &&
                               e.fechaInicio.year == _focusedDate.year;
                      }).toList();
                    }

                    // Eventos del día seleccionado
                    final eventosDelDia = eventosDelMes.where((e) {
                      final eventoFecha = DateTime(e.fechaInicio.year, e.fechaInicio.month, e.fechaInicio.day);
                      final diaSeleccionado = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day);
                      return eventoFecha.isAtSameMomentAs(diaSeleccionado);
                    }).toList();
                    eventosDelDia.sort((a, b) => a.fechaInicio.compareTo(b.fechaInicio));

                    return Column(
                      children: [
                        // CONTROLES DE MES
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              // [CAMBIO 3] Degradado sutil que termina en el color de la tarjeta
                              colors: isDark 
                                ? [
                                    theme.cardTheme.color!.withValues(alpha: 0.5),
                                    theme.cardTheme.color!,
                                  ]
                                : [
                                    const Color(0xFFA5BBC3).withValues(alpha: 0.08),
                                    Colors.white,
                                  ],
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5E81AC).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded, 
                                    size: 28, color: Color(0xFF5E81AC)),
                                  onPressed: _previousMonth,
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                              
                              Text(
                                monthTitle,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: mainTextColor, // Color dinámico
                                  letterSpacing: 0.5,
                                ),
                              ),

                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF5E81AC).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded, 
                                    size: 28, color: Color(0xFF5E81AC)),
                                  onPressed: _nextMonth,
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // DÍAS DE LA SEMANA
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['L', 'M', 'X', 'J', 'V', 'S', 'D'].map((day) {
                              return Expanded(
                                child: Center(
                                  child: Text(
                                    day,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                        ),

                        const SizedBox(height: 8),

                        // GRILLA DE DÍAS
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: AspectRatio(
                            aspectRatio: 1.4,
                            child: GridView.builder(
                              padding: EdgeInsets.zero,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                crossAxisSpacing: 6,
                                mainAxisSpacing: 6,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: daysInMonth + (firstDayOfWeek - 1),
                              itemBuilder: (context, index) {
                                if (index < firstDayOfWeek - 1) {
                                  return const SizedBox.shrink();
                                }
                                
                                final dayNumber = index - (firstDayOfWeek - 1) + 1;
                                final currentDate = DateTime(_focusedDate.year, _focusedDate.month, dayNumber);
                                final isToday = _isToday(currentDate);
                                final isSelected = _isSameDay(currentDate, _selectedDay);
                                
                                final eventosDelDiaCelda = eventosDelMes.where((e) => 
                                  e.fechaInicio.day == dayNumber).toList();
                                
                                Evento? eventoPrincipal;
                                if (eventosDelDiaCelda.isNotEmpty) {
                                  eventosDelDiaCelda.sort((a, b) {
                                    return b.tipo.index.compareTo(a.tipo.index);
                                  }); 
                                  eventoPrincipal = eventosDelDiaCelda.first;
                                }

                                return _buildDayCell(
                                  context,
                                  dayNumber, 
                                  eventoPrincipal, 
                                  isToday,
                                  isSelected,
                                  eventosDelDiaCelda.length,
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // LÍNEA SEPARADORA
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
                        ),

                        // LISTA DE EVENTOS DEL DÍA SELECCIONADO
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.event_rounded,
                                      size: 20,
                                      color: Color(0xFF5E81AC),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('d MMMM', 'es_ES').format(_selectedDay),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: mainTextColor, // Color dinámico
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (eventosDelDia.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF5E81AC).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '${eventosDelDia.length}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF5E81AC),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: eventosDelDia.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.event_busy_rounded,
                                            size: 48,
                                            color: isDark ? Colors.white10 : Colors.grey[300],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Sin eventos',
                                            style: TextStyle(
                                              color: isDark ? Colors.white30 : Colors.grey[400],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                                      itemCount: eventosDelDia.length,
                                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                                      itemBuilder: (context, index) {
                                        final evento = eventosDelDia[index];
                                        return _buildEventCard(context, evento);
                                      },
                                    ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      
      floatingActionButton: Container(
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
    );
  }

  // CELDA DE DÍA ADAPTADA
  Widget _buildDayCell(BuildContext context, int day, Evento? evento, bool isToday, bool isSelected, int eventCount) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bodyColor = theme.textTheme.bodyLarge?.color;

    // [CAMBIO 4] Fondo de celda sutil en modo oscuro
    final defaultBgColor = isDark 
        ? Colors.white.withValues(alpha: 0.05) 
        : const Color(0xFFF5F5F5);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDay = DateTime(_focusedDate.year, _focusedDate.month, day);
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isToday 
            ? const Color(0xFF5E81AC).withValues(alpha: 0.15)
            : isSelected
              ? const Color(0xFF99C2FF).withValues(alpha: 0.2)
              : defaultBgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isToday 
              ? const Color(0xFF5E81AC)
              : isSelected
                ? const Color(0xFF99C2FF)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: const Color(0xFF99C2FF).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  "$day",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    // Texto adaptativo
                    color: isToday 
                      ? const Color(0xFF5E81AC)
                      : bodyColor,
                  ),
                ),
              ),
            ),
            
            if (evento != null)
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Icon(
                      evento.tipo.icono,
                      color: evento.tipo.color,
                      size: 14,
                    ),
                    if (eventCount > 1)
                      Container(
                        margin: const EdgeInsets.only(top: 1),
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                        decoration: BoxDecoration(
                          color: evento.tipo.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '+${eventCount - 1}',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: evento.tipo.color,
                          ),
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

  // TARJETA DE EVENTO MINI ADAPTADA
  Widget _buildEventCard(BuildContext context, Evento evento) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a', 'es_ES');
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: evento.tipo.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: evento.tipo.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: evento.tipo.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              evento.tipo.icono,
              color: evento.tipo.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  evento.titulo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    // [CAMBIO 5] Color de texto de evento adaptativo
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      evento.todoElDia ? Icons.calendar_today_rounded : Icons.access_time_rounded,
                      size: 12,
                      color: Colors.grey[600], // Este gris suele verse bien en ambos modos
                    ),
                    const SizedBox(width: 4),
                    Text(
                      evento.todoElDia ? 'Todo el día' : timeFormat.format(evento.fechaInicio),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }
}