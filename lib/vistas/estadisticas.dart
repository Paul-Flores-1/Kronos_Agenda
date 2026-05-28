import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import '../models/evento_model.dart';
import 'menu.dart';


class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    // Obtenemos el tema y detectamos el modo
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mainTextColor = theme.textTheme.titleLarge?.color;

    return Scaffold(
      body: Column(
        children: [
          
          // 1. CABECERA
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Menú Adaptado
                  Container(
                    decoration: BoxDecoration(
                      color: isDark 
                          ? Colors.white.withValues(alpha: 0.1) 
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.menu_rounded, size: 28, color: mainTextColor),
                      onPressed: () {
                         Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const MenuScreen()),
                        );
                      },
                    ),
                  ),
                  Text(
                    "Estadísticas",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: mainTextColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  // Espacio vacío para equilibrar la cabecera
                  const SizedBox(width: 48), 
                ],
              ),
            ),
          ),

          // ============================================
          // 2. CONTENIDO PRINCIPAL (GRÁFICOS)
          // ============================================
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                // [CAMBIO] Color de fondo dinámico (Gris oscuro en noche, Blanco en día)
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
              child: StreamBuilder<List<Evento>>(
                stream: _authService.getEvents(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF5E81AC)));
                  }

                  final eventos = snapshot.data ?? [];

                  // Divisor sutil adaptado
                  final dividerColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFEEEEEE);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(top: 10, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ChartCard(
                          title: "Hoy",
                          subtitle: "Tiempo ocupado del día",
                          eventos: eventos,
                          periodo: _Periodo.dia,
                        ),
                        const SizedBox(height: 24),
                        Divider(height: 1, thickness: 1, color: dividerColor),
                        const SizedBox(height: 24),
                        _ChartCard(
                          title: "Esta Semana",
                          subtitle: "Productividad semanal",
                          eventos: eventos,
                          periodo: _Periodo.semana,
                        ),
                        const SizedBox(height: 24),
                        Divider(height: 1, thickness: 1, color: dividerColor),
                        const SizedBox(height: 24),
                        _ChartCard(
                          title: "Este Mes",
                          subtitle: "Balance mensual",
                          eventos: eventos,
                          periodo: _Periodo.mes,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Enum interno
enum _Periodo { dia, semana, mes }

// Widget de Tarjeta de Gráfico
class _ChartCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<Evento> eventos;
  final _Periodo periodo;

  const _ChartCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.eventos,
    required this.periodo,
  });

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  int touchedIndex = -1; 

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Filtrar eventos y calcular totales
    final now = DateTime.now();
    List<Evento> eventosFiltrados = [];
    double totalHorasDisponibles = 0;

    switch (widget.periodo) {
      case _Periodo.dia:
        totalHorasDisponibles = 24;
        eventosFiltrados = widget.eventos.where((e) {
          return e.fechaInicio.day == now.day &&
                 e.fechaInicio.month == now.month &&
                 e.fechaInicio.year == now.year;
        }).toList();
        break;
      case _Periodo.semana:
        totalHorasDisponibles = 24 * 7;
        final lunes = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        final domingo = lunes.add(const Duration(days: 6, hours: 23, minutes: 59));
        
        eventosFiltrados = widget.eventos.where((e) {
          return e.fechaInicio.isAfter(lunes.subtract(const Duration(seconds: 1))) &&
                 e.fechaInicio.isBefore(domingo);
        }).toList();
        break;
      case _Periodo.mes:
        final diasEnMes = DateUtils.getDaysInMonth(now.year, now.month);
        totalHorasDisponibles = 24.0 * diasEnMes;
        eventosFiltrados = widget.eventos.where((e) {
          return e.fechaInicio.month == now.month && e.fechaInicio.year == now.year;
        }).toList();
        break;
    }

    // 2. Sumar horas por tipo
    Map<TipoEvento, double> horasPorTipo = {
      TipoEvento.cotidiano: 0,
      TipoEvento.recordatorio: 0,
      TipoEvento.especial: 0,
      TipoEvento.muyEspecial: 0,
    };

    double horasOcupadasTotal = 0;

    for (var e in eventosFiltrados) {
      double duracion = 0;
      if (e.todoElDia) {
        duracion = 24.0; 
      } else {
        final diff = e.fechaFin.difference(e.fechaInicio).inMinutes;
        duracion = diff / 60.0;
      }
      
      if (horasOcupadasTotal + duracion > totalHorasDisponibles) {
        duracion = totalHorasDisponibles - horasOcupadasTotal;
      }
      
      horasPorTipo[e.tipo] = (horasPorTipo[e.tipo] ?? 0) + duracion;
      horasOcupadasTotal += duracion;
    }

    // 3. Calcular tiempo libre
    double horasLibres = totalHorasDisponibles - horasOcupadasTotal;
    if (horasLibres < 0) horasLibres = 0;

    // 4. Preparar datos para UI
    final porcentajeOcupado = (horasOcupadasTotal / totalHorasDisponibles) * 100;
    
    // [CAMBIO] Color de "Tiempo Libre" dinámico
    final freeTimeColor = isDark 
        ? Colors.white.withValues(alpha: 0.05) // Gris muy oscuro/translúcido en modo noche
        : const Color(0xFFF0F2F5); // Gris claro original

    List<PieChartSectionData> secciones = [];
    
    PieChartSectionData buildSection(Color color, double value) {
      // Ajuste visual: en modo oscuro los colores pueden ser un poco más transparentes si lo deseas,
      // pero por ahora mantendremos los colores originales de los tipos.
      return PieChartSectionData(
        color: color,
        value: value,
        title: '', 
        radius: 22.0,
        showTitle: false,
        badgeWidget: null, 
      );
    }

    horasPorTipo.forEach((tipo, horas) {
      if (horas > 0) {
        secciones.add(buildSection(tipo.color, horas));
      }
    });

    if (horasLibres > 0) {
      secciones.add(PieChartSectionData(
        color: freeTimeColor,
        value: horasLibres,
        title: '',
        radius: 18.0, 
        showTitle: false,
      ));
    }

    if (secciones.isEmpty) {
        secciones.add(PieChartSectionData(
        color: freeTimeColor,
        value: 1,
        title: '',
        radius: 18.0,
        showTitle: false,
      ));
    }

    return Column(
      children: [
        // Títulos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    // [CAMBIO] Texto adaptativo
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500], // El gris medio suele verse bien en ambos
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Chip de porcentaje total
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                // [CAMBIO] Fondo del chip adaptado
                color: porcentajeOcupado > 50 
                    ? const Color(0xFF5E81AC).withValues(alpha: isDark ? 0.2 : 0.1) 
                    : const Color(0xFF8DA9B3).withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${porcentajeOcupado.toStringAsFixed(1)}% Ocupado",
                style: TextStyle(
                  // [CAMBIO] Texto del chip un poco más claro en modo oscuro para contraste
                  color: porcentajeOcupado > 50 
                      ? (isDark ? const Color(0xFF8FAACF) : const Color(0xFF5E81AC))
                      : (isDark ? const Color(0xFFA5BBC3) : const Color(0xFF1E2D3A)),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),

        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // GRÁFICO (Lado Izquierdo)
            SizedBox(
              height: 140,
              width: 140,
              child: Stack(
                children: [
                  PieChart(
                    PieChartData(
                      sections: secciones,
                      centerSpaceRadius: 50, 
                      sectionsSpace: 2, 
                      startDegreeOffset: -90,
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                  // Texto Central
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${porcentajeOcupado.toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            // [CAMBIO] Color del número central
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const Text(
                          "Uso",
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(width: 20),

            // LEYENDA (Lado Derecho)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...horasPorTipo.entries.where((e) => e.value > 0).map((entry) {
                    final porcentajeTipo = (entry.value / totalHorasDisponibles) * 100;
                    return _LegendItem(
                      color: entry.key.color,
                      label: entry.key.toString().split('.').last, 
                      percentage: porcentajeTipo,
                    );
                  }),
                  
                  // Item de Tiempo Libre
                  _LegendItem(
                    color: freeTimeColor,
                    label: "Libre",
                    percentage: (horasLibres / totalHorasDisponibles) * 100,
                    isFreeTime: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Widget pequeño para cada fila de la leyenda
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final double percentage;
  final bool isFreeTime;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.percentage,
    this.isFreeTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Capitalizar primera letra
    final labelFormat = label[0].toUpperCase() + label.substring(1);

    // [CAMBIO] Colores de texto para leyenda
    final labelColor = isFreeTime 
        ? Colors.grey[500] 
        : theme.textTheme.bodyLarge?.color; // Color principal del tema

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              // Si es freeTime en modo oscuro, le damos un color visible (gris) 
              // en lugar del casi transparente del gráfico
              color: isFreeTime && isDark ? Colors.grey[700] : color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              labelFormat,
              style: TextStyle(
                fontSize: 12,
                color: labelColor,
                fontWeight: isFreeTime ? FontWeight.normal : FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            "${percentage.toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}