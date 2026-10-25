import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart'; 
import '../../providers/eventos_provider.dart'; 
import '../../models/evento_model.dart';
import '../usuario/menu.dart';

class EstadisticasScreen extends StatefulWidget {
  const EstadisticasScreen({super.key});

  @override
  State<EstadisticasScreen> createState() => _EstadisticasScreenState();
}

class _EstadisticasScreenState extends State<EstadisticasScreen> {
  
  // --- ANIMACIÓN HACIA LA DERECHA (PARA VOLVER AL MENÚ) ---
  Route _rutaHaciaDerecha(Widget vista) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => vista,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0); // Entra desde la izquierda
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Color de texto para la cabecera (hace contraste con el fondo azul degradado)
    final headerTextColor = isDark ? Colors.white : const Color(0xFF1E2D3A);

    return Scaffold(
      body: Container(
        // AQUÍ ESTÁ EL FONDO AZUL DEGRADADO QUE FALTABA
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
                ? [const Color(0xFF15202B), const Color(0xFF1E2D3A)] 
                : [const Color(0xFFA5BBC3), const Color(0xFF8DA9B3)],
          ),
        ),
        child: Column(
          children: [
            // 1. CABECERA
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.3), 
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: headerTextColor),
                        onPressed: () => Navigator.pushReplacement(context, _rutaHaciaDerecha(const MenuScreen())),
                      ),
                    ),
                    Text(
                      "Estadísticas", 
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: headerTextColor, letterSpacing: -0.5)
                    ),
                    const SizedBox(width: 48), 
                  ],
                ),
              ),
            ),

            // 2. CONTENIDO PRINCIPAL (PANEL BLANCO/OSCURO)
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10), spreadRadius: -5)
                  ],
                ),
                child: Consumer<EventosProvider>(
                  builder: (context, eventosProvider, child) {
                    if (eventosProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF5E81AC)));
                    }

                    final eventos = eventosProvider.eventos;
                    final dividerColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFEEEEEE);

                    // Sin scroll, todo se adapta al Expanded
                    return Column(
                      children: [
                        Expanded(
                          child: _ChartCard(
                            title: "Hoy", 
                            subtitle: "Tiempo ocupado del día", 
                            eventos: eventos, 
                            periodo: _Periodo.dia,
                            indexAnimacion: 0, 
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1, thickness: 1, color: dividerColor),
                        ),
                        Expanded(
                          child: _ChartCard(
                            title: "Esta Semana", 
                            subtitle: "Productividad semanal", 
                            eventos: eventos, 
                            periodo: _Periodo.semana,
                            indexAnimacion: 1, 
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1, thickness: 1, color: dividerColor),
                        ),
                        Expanded(
                          child: _ChartCard(
                            title: "Este Mes", 
                            subtitle: "Balance mensual", 
                            eventos: eventos, 
                            periodo: _Periodo.mes,
                            indexAnimacion: 2, 
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _Periodo { dia, semana, mes }

class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Evento> eventos;
  final _Periodo periodo;
  final int indexAnimacion;

  const _ChartCard({
    required this.title, 
    required this.subtitle, 
    required this.eventos, 
    required this.periodo,
    required this.indexAnimacion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    
    List<Evento> eventosFiltrados = [];
    double totalHorasDisponibles = 0;

    switch (periodo) {
      case _Periodo.dia:
        totalHorasDisponibles = 24;
        eventosFiltrados = eventos.where((e) => e.fechaInicio.day == now.day && e.fechaInicio.month == now.month && e.fechaInicio.year == now.year).toList();
        break;
      case _Periodo.semana:
        totalHorasDisponibles = 24 * 7;
        final lunes = DateTime(now.year, now.month, now.day - (now.weekday - 1));
        final domingo = lunes.add(const Duration(days: 6, hours: 23, minutes: 59));
        eventosFiltrados = eventos.where((e) => e.fechaInicio.isAfter(lunes.subtract(const Duration(seconds: 1))) && e.fechaInicio.isBefore(domingo)).toList();
        break;
      case _Periodo.mes:
        final diasEnMes = DateUtils.getDaysInMonth(now.year, now.month);
        totalHorasDisponibles = 24.0 * diasEnMes;
        eventosFiltrados = eventos.where((e) => e.fechaInicio.month == now.month && e.fechaInicio.year == now.year).toList();
        break;
    }

    Map<TipoEvento, double> horasPorTipo = {
      TipoEvento.cotidiano: 0, 
      TipoEvento.recordatorio: 0, 
      TipoEvento.especial: 0, 
      TipoEvento.muyEspecial: 0, 
      TipoEvento.cumpleanos: 0,
      TipoEvento.festivo: 0,
    };
    
    double horasOcupadasTotal = 0;

    for (var e in eventosFiltrados) {
      if (e.tipo == TipoEvento.festivo) continue;

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

    double horasLibresReal = totalHorasDisponibles - horasOcupadasTotal;
    if (horasLibresReal < 0) horasLibresReal = 0;

    final porcentajeOcupadoReal = (horasOcupadasTotal / totalHorasDisponibles) * 100;
    final freeTimeColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F2F5); 

    // --- ANIMACIÓN MÁS LENTA Y VISIBLE ---
    return TweenAnimationBuilder<double>(
      key: ValueKey(title),
      // Aumentamos la duración a más de 2 segundos para que aprecies bien el velocímetro
      duration: Duration(milliseconds: 2400 + (indexAnimacion * 400)), 
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: Curves.linear, 
      builder: (context, t, child) {
        
        // 1. Animación de Opacidad (Aparece suave en el primer 25% del tiempo)
        double tEntrada = (t / 0.25).clamp(0.0, 1.0);
        double opacidad = Curves.easeOut.transform(tEntrada);
        double desplazamiento = 1.0 - Curves.easeOutCubic.transform(tEntrada);

        // 2. Velocímetro ralentizado
        double ratioOcupacion = 0.0;
        
        if (t < 0.35) {
          // Fase 1: Sube hasta el 100% de la barra
          double tSubida = t / 0.35;
          ratioOcupacion = Curves.easeOutQuart.transform(tSubida);
        } else {
          // Fase 2: Cae MUY suavemente hasta tu porcentaje real en el 65% del tiempo restante
          double tBajada = (t - 0.35) / 0.65;
          double ratioReal = totalHorasDisponibles > 0 ? horasOcupadasTotal / totalHorasDisponibles : 0.0;
          ratioOcupacion = 1.0 - ((1.0 - ratioReal) * Curves.easeInOutCubic.transform(tBajada));
        }

        double horasOcupadasDisplay = ratioOcupacion * totalHorasDisponibles;
        double horasLibresDisplay = totalHorasDisponibles - horasOcupadasDisplay;
        if (horasLibresDisplay < 0) horasLibresDisplay = 0;

        List<PieChartSectionData> secciones = [];
        
        if (horasOcupadasDisplay > 0.001) { 
          if (horasOcupadasTotal > 0) {
            horasPorTipo.forEach((tipo, horas) {
              if (horas > 0) {
                double sectionVal = horasOcupadasDisplay * (horas / horasOcupadasTotal);
                secciones.add(PieChartSectionData(color: tipo.color, value: sectionVal, radius: 18.0, showTitle: false));
              }
            });
          } else {
            // "Fantasma" si no hay eventos
            secciones.add(PieChartSectionData(
              color: const Color(0xFF5E81AC).withValues(alpha: isDark ? 0.3 : 0.15), 
              value: horasOcupadasDisplay, 
              radius: 18.0, 
              showTitle: false
            ));
          }
        }
        
        if (horasLibresDisplay > 0.001) {
          secciones.add(PieChartSectionData(color: freeTimeColor, value: horasLibresDisplay, radius: 14.0, showTitle: false));
        }

        return Opacity(
          opacity: opacidad,
          child: Transform.translate(
            offset: Offset(0, 30 * desplazamiento),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start, 
                      children: [
                        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.textTheme.titleLarge?.color)), 
                        Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500))
                      ]
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                      decoration: BoxDecoration(
                        color: porcentajeOcupadoReal > 50 ? const Color(0xFF5E81AC).withValues(alpha: isDark ? 0.2 : 0.1) : const Color(0xFF8DA9B3).withValues(alpha: isDark ? 0.2 : 0.1), 
                        borderRadius: BorderRadius.circular(16)
                      ), 
                      child: Text(
                        "${porcentajeOcupadoReal.toStringAsFixed(1)}% Ocup.", 
                        style: TextStyle(color: porcentajeOcupadoReal > 50 ? (isDark ? const Color(0xFF8FAACF) : const Color(0xFF5E81AC)) : (isDark ? const Color(0xFFA5BBC3) : const Color(0xFF1E2D3A)), fontWeight: FontWeight.bold, fontSize: 11)
                      )
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 110, width: 110,
                        child: Stack(
                          children: [
                            PieChart(
                              PieChartData(
                                sections: secciones, 
                                centerSpaceRadius: 36, 
                                sectionsSpace: 2, 
                                startDegreeOffset: -90, 
                                borderData: FlBorderData(show: false)
                              ),
                              swapAnimationDuration: Duration.zero, 
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min, 
                                children: [
                                  Text(
                                    "${(ratioOcupacion * 100).toStringAsFixed(0)}%", 
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: theme.textTheme.titleLarge?.color)
                                  ), 
                                  const Text("Uso", style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w600))
                                ]
                              )
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ...horasPorTipo.entries.where((e) => e.value > 0).map((entry) => 
                                _LegendItem(color: entry.key.color, label: entry.key.etiqueta, percentage: (entry.value / totalHorasDisponibles) * 100)
                              ),
                              _LegendItem(color: freeTimeColor, label: "Libre", percentage: (horasLibresReal / totalHorasDisponibles) * 100, isFreeTime: true),
                            ],
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
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color; 
  final String label; 
  final double percentage; 
  final bool isFreeTime;
  
  const _LegendItem({required this.color, required this.label, required this.percentage, this.isFreeTime = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final labelFormat = label[0].toUpperCase() + label.substring(1);
    final labelColor = isFreeTime ? Colors.grey[500] : theme.textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: isFreeTime && isDark ? Colors.grey[700] : color, shape: BoxShape.circle)
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(labelFormat, style: TextStyle(fontSize: 11, color: labelColor, fontWeight: isFreeTime ? FontWeight.normal : FontWeight.w600), overflow: TextOverflow.ellipsis)
          ),
          Text(
            "${percentage.toStringAsFixed(1)}%", 
            style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.bold)
          ),
        ],
      ),
    );
  }
}