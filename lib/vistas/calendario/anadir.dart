import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../models/evento_model.dart';
import 'package:kronos/services/notification_service.dart';

class AddEventScreen extends StatefulWidget {
  final Evento? eventoParaEditar;

  const AddEventScreen({super.key, this.eventoParaEditar});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TextEditingController _titleController;
  late TextEditingController _descController;

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  late String _selectedType;
  late bool _isAllDay;
  bool _isLoading = false;

  List<int> _selectedReminders = [];

  bool get _isEditing => widget.eventoParaEditar != null;
  bool get _isReminderType => _selectedType == 'recordatorio';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut, reverseCurve: Curves.easeOut)
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart, reverseCurve: Curves.easeIn)
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuad, reverseCurve: Curves.easeInBack)
    );

    _animationController.forward();

    if (_isEditing) {
      final e = widget.eventoParaEditar!;
      _titleController = TextEditingController(text: e.titulo);
      _descController = TextEditingController(text: e.descripcion);
      _selectedDate = e.fechaInicio;
      _startTime = TimeOfDay.fromDateTime(e.fechaInicio);
      _endTime = TimeOfDay.fromDateTime(e.fechaFin);
      _selectedType = e.tipo.toString().split('.').last;
      _isAllDay = e.esTodoElDia;
    } else {
      _titleController = TextEditingController();
      _descController = TextEditingController();
      _selectedDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay.now().replacing(hour: (TimeOfDay.now().hour + 1) % 24);
      _selectedType = 'cotidiano';
      _isAllDay = false;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _closeScreen() {
    if (_animationController.status == AnimationStatus.reverse || 
        _animationController.status == AnimationStatus.dismissed) {
      return;
    }
    _animationController.reverse().then((_) {
      if (mounted) Navigator.pop(context);
    });
  }

  Map<String, int> get _reminderOptions {
    if (_isReminderType) {
      return {
        "1 hora antes": 60, "2 horas antes": 120, "3 horas antes": 180, "4 horas antes": 240, "5 horas antes": 300,
      };
    } else {
      return {
        "1 hora antes": 60, "2 horas antes": 120, "un día antes": 1440, "una semana antes": 10080, "2 semanas antes": 20160, "un mes antes": 43200,
      };
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'muyEspecial': return const Color(0xFFF59E0B);
      case 'especial': return const Color(0xFFA78BFA);
      case 'cotidiano': return const Color(0xFF60A5FA);
      case 'recordatorio': return const Color(0xFFFB923C);
      case 'cumpleaños': return const Color(0xFFF472B6);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        _closeScreen();
        return false;
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: _closeScreen,
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(76),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(50), width: 1),
                        ),
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: theme.textTheme.bodyLarge?.color),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _isEditing ? 'Editar Evento' : 'Nuevo Evento',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: theme.textTheme.titleLarge?.color, letterSpacing: -0.3),
                    ),
                  ],
                ),
              ),
      
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [BoxShadow(color: Colors.black.withAlpha(18), blurRadius: 16, offset: const Offset(0, 6))],
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel("Título"),
                              _buildTextField(
                                controller: _titleController,
                                hint: "Ej: Cita con el doctor",
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                              ),
                              const SizedBox(height: 22),
      
                              _buildLabel("Tipo de evento"),
                              Container(
                                width: double.infinity,
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                                  children: [
                                    _buildTypeSelector('muyEspecial', Icons.star_rounded, "Especial"),
                                    _buildTypeSelector('especial', Icons.people_alt_rounded, "Social"),
                                    _buildTypeSelector('cotidiano', Icons.work_outline_rounded, "Casual"),
                                    _buildTypeSelector('recordatorio', Icons.notifications_active_rounded, "Aviso"),
                                    _buildTypeSelector('cumpleaños', Icons.cake_rounded, "Cumple"),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 22),
      
                              _buildLabel("Recordatorios"),
                              Wrap(
                                spacing: 8, runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  ..._selectedReminders.map((mins) {
                                    final label = _reminderOptions.entries.firstWhere((e) => e.value == mins, orElse: () => MapEntry("$mins min", mins)).key;
                                    return _buildReminderChip(label, mins);
                                  }),
                                  _buildAddReminderButton(),
                                ],
                              ),
                              const SizedBox(height: 22),
      
                              _buildLabel("Fecha"),
                              _buildDatePicker(),
                              const SizedBox(height: 16),
      
                              Row(
                                children: [
                                  Expanded(child: _buildTimePicker("Inicio", true)),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildTimePicker("Fin", false)),
                                ],
                              ),
                              const SizedBox(height: 16),
      
                              _buildToggleRow(),
                              const SizedBox(height: 16),
      
                              _buildLabel("Descripción"),
                              TextField(
                                controller: _descController,
                                maxLines: 3,
                                style: const TextStyle(fontSize: 14),
                                decoration: _inputDecoration("Detalles adicionales..."),
                              ),
                              const SizedBox(height: 32),
      
                              _buildSaveButton(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8), letterSpacing: 0.7)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, TextStyle? style, int maxLines = 1}) {
    return TextField(controller: controller, style: style, maxLines: maxLines, decoration: _inputDecoration(hint));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint, hintStyle: const TextStyle(color: Color(0xFFA0ADB8), fontSize: 14),
      filled: true, fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEEF2F7), width: 1.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFEEF2F7), width: 1.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF99C2FF), width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTypeSelector(String type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    final color = _typeColor(type);
    return GestureDetector(
      onTap: () => setState(() {
        _selectedType = type;
        if (type == 'cumpleanos') _isAllDay = true;
        _selectedReminders.clear();
      }),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: isSelected ? color.withAlpha(30) : Colors.transparent,
              border: Border.all(color: isSelected ? color : const Color(0xFFE2E8F0), width: 2),
              shape: BoxShape.circle,
              boxShadow: isSelected ? [BoxShadow(color: color.withAlpha(50), blurRadius: 10, offset: const Offset(0, 3))] : [],
            ),
            child: Icon(icon, color: isSelected ? color : const Color(0xFFCBD5E1), size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? color : const Color(0xFFCBD5E1))),
        ],
      ),
    );
  }

  Widget _buildReminderChip(String label, int mins) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 6, top: 6, bottom: 6),
      decoration: BoxDecoration(color: const Color(0xFF5E81AC).withAlpha(20), borderRadius: BorderRadius.circular(100), border: Border.all(color: const Color(0xFF5E81AC).withAlpha(60), width: 1.5)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF3D5A8A))),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _selectedReminders.remove(mins)),
            child: Container(width: 18, height: 18, decoration: BoxDecoration(color: Colors.red.withAlpha(25), shape: BoxShape.circle), child: const Icon(Icons.close, size: 11, color: Color(0xFFEF4444))),
          ),
        ],
      ),
    );
  }

  Widget _buildAddReminderButton() {
    return GestureDetector(
      onTap: _showReminderPicker,
      child: Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF5E81AC), width: 1.5)), child: const Icon(Icons.add, size: 18, color: Color(0xFF5E81AC))),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEF2F7), width: 1.5)),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF94A3B8)),
            const SizedBox(width: 10),
            Text(DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E2D3A))),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, bool isStart) {
    final bool disabled = !isStart && (_isAllDay || _isReminderType);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        GestureDetector(
          onTap: (_isAllDay || (disabled && !isStart)) ? null : () => _pickTime(isStart: isStart),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(color: disabled ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEF2F7), width: 1.5)),
            child: Row(
              children: [
                Icon(isStart ? Icons.access_time_rounded : Icons.update_rounded, size: 16, color: disabled ? const Color(0xFFCBD5E1) : const Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Text(_isAllDay ? "--:--" : _formatTimeOfDay(isStart ? _startTime : _endTime), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: disabled ? const Color(0xFFCBD5E1) : const Color(0xFF1E2D3A))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFEEF2F7), width: 1.5)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Icon(Icons.wb_sunny_outlined, size: 18, color: const Color(0xFF94A3B8)), const SizedBox(width: 10), const Text("Todo el día", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF1E2D3A)))]),
          Switch(value: _isAllDay, activeColor: Colors.white, activeTrackColor: const Color(0xFF99C2FF), inactiveThumbColor: Colors.white, inactiveTrackColor: const Color(0xFFE2E8F0), onChanged: (val) => setState(() => _isAllDay = val)),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity, height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E2D3A), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
        onPressed: _isLoading ? null : _validateAndSave,
        icon: _isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_rounded, size: 20),
        label: Text(_isEditing ? "Guardar Cambios" : "Crear Evento", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
      ),
    );
  }

  void _showReminderPicker() {
    final start = DateTime(
      _selectedDate.year, 
      _selectedDate.month, 
      _selectedDate.day, 
      _startTime.hour, 
      _startTime.minute
    );
    final ahora = DateTime.now();

    final opcionesValidas = _reminderOptions.entries.where((option) {
      final notifDate = start.subtract(Duration(minutes: option.value));
      return notifDate.isAfter(ahora);
    }).toList();

    showModalBottomSheet(
      context: context, 
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(100)))),
              const SizedBox(height: 16),
              const Text("Agregar recordatorio", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E2D3A))),
              const SizedBox(height: 8),
              
              if (opcionesValidas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      "El evento está muy próximo para agregar estos recordatorios.",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...opcionesValidas.map((option) {
                  final alreadyAdded = _selectedReminders.contains(option.value);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: alreadyAdded ? const Color(0xFF5E81AC).withAlpha(20) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.alarm_outlined, size: 18, color: alreadyAdded ? const Color(0xFF5E81AC) : const Color(0xFF94A3B8))),
                    title: Text(option.key, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: alreadyAdded ? const Color(0xFF5E81AC) : const Color(0xFF1E2D3A))),
                    trailing: alreadyAdded ? const Icon(Icons.check_circle_rounded, color: Color(0xFF5E81AC), size: 20) : null,
                    onTap: () { 
                      if (!alreadyAdded) {
                        setState(() => _selectedReminders.add(option.value)); 
                      }
                      Navigator.pop(ctx); 
                    },
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('h:mm a', 'en_US').format(dt); 
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime(2030));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
      initialEntryMode: TimePickerEntryMode.input, 
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: Localizations.override(
            context: context,
            locale: const Locale('en', 'US'), 
            child: child!,
          ),
        );
      },
    );
    if (picked != null) {
      setState(() { 
        if (isStart) { 
          _startTime = picked; 
          if (_isReminderType) _endTime = _startTime; 
        } else { 
          _endTime = picked; 
        } 
      });
    }
  }

  void _validateAndSave() async {
    if (_titleController.text.isEmpty) { 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El título es obligatorio"))); 
      return; 
    }
    setState(() => _isLoading = true);
    
    final start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _startTime.hour, _startTime.minute);
    final end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _endTime.hour, _endTime.minute);
    
    try {
      if (_isEditing) { 
        await _authService.updateEvent(eventId: widget.eventoParaEditar!.id, title: _titleController.text.trim(), description: _descController.text.trim(), startDate: start, endDate: end, isAllDay: _isAllDay, type: _selectedType); 
      } else { 
        await _authService.createEvent(title: _titleController.text.trim(), description: _descController.text.trim(), startDate: start, endDate: end, isAllDay: _isAllDay, type: _selectedType); 
      }
      
      for (int mins in _selectedReminders) {
        final notifDate = start.subtract(Duration(minutes: mins));
        
        if (notifDate.isAfter(DateTime.now())) {
          String cuerpoPersonalizado = 'Tu evento "${_titleController.text.trim()}" está a punto de empezar.';
          final horaFormateada = DateFormat('h:mm a', 'es_ES').format(start);

          if (mins == 43200) { 
            cuerpoPersonalizado = 'Recuerda que el próximo mes tienes el evento "${_titleController.text.trim()}" a las $horaFormateada.';
          } else if (mins == 20160) {
            cuerpoPersonalizado = 'Recuerda que en 2 semanas tienes el evento "${_titleController.text.trim()}" a las $horaFormateada.';
          } else if (mins == 10080) { 
            cuerpoPersonalizado = 'Recuerda que la próxima semana tienes el evento "${_titleController.text.trim()}" a las $horaFormateada.';
          } else if (mins == 1440) { 
            cuerpoPersonalizado = 'Recuerda que el día de mañana tienes el evento "${_titleController.text.trim()}" a las $horaFormateada.';
          } else if (mins == 120) {
            cuerpoPersonalizado = 'Tu evento "${_titleController.text.trim()}" empieza en 2 horas (a las $horaFormateada).';
          } else if (mins == 60) { 
            cuerpoPersonalizado = 'Tu evento "${_titleController.text.trim()}" empieza en una hora (a las $horaFormateada).';
          }
          
          await NotificationService.programarNotificacion(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000 + mins, 
            titulo: 'Recordatorio Kronos', 
            cuerpo: cuerpoPersonalizado,
            fecha: notifDate
          );
        }
      }
      
      if (mounted) _closeScreen();
      
    } catch (e) { 
      if (mounted) { 
        setState(() => _isLoading = false); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"))); 
      } 
    }
  }
}