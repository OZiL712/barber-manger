import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/haircut_provider.dart';
import '../../../core/models/haircut.dart';
import '../../../core/models/barber_service.dart';

class AddEditHaircutScreen extends StatefulWidget {
  final Haircut? haircut;

  const AddEditHaircutScreen({super.key, this.haircut});

  @override
  State<AddEditHaircutScreen> createState() => _AddEditHaircutScreenState();
}

class _AddEditHaircutScreenState extends State<AddEditHaircutScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _opNumberController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;
  late TextEditingController _receivedController;
  late TextEditingController _notesController;

  List<BarberService> _selectedServices = [];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    _opNumberController = TextEditingController(
      text: widget.haircut?.operationNumber ?? 'OP-${now.millisecondsSinceEpoch}',
    );
    _dateController = TextEditingController(
      text: widget.haircut?.date ?? DateFormat('yyyy-MM-dd').format(now),
    );
    // 12-hour format with AM / PM (من 1 إلى 12 مع AM أو PM)
    _timeController = TextEditingController(
      text: widget.haircut?.time ?? DateFormat('hh:mm a').format(now),
    );
    _receivedController = TextEditingController(
      text: widget.haircut?.amountReceived.toString() ?? '',
    );
    _notesController = TextEditingController(
      text: widget.haircut?.notes ?? '',
    );

    if (widget.haircut != null) {
      _selectedServices = List.from(widget.haircut!.services);
    }
  }

  @override
  void dispose() {
    _opNumberController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _receivedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final now = DateTime.now();
    TimeOfDay initialTime = TimeOfDay.fromDateTime(now);

    final currentText = _timeController.text.trim();
    if (currentText.isNotEmpty) {
      try {
        final parsed = DateFormat('hh:mm a').parse(currentText);
        initialTime = TimeOfDay.fromDateTime(parsed);
      } catch (_) {
        try {
          final parsed = DateFormat('HH:mm').parse(currentText);
          initialTime = TimeOfDay.fromDateTime(parsed);
        } catch (_) {}
      }
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      final formatted = DateFormat('hh:mm a').format(dt);
      setState(() {
        _timeController.text = formatted;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final initialDate = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      locale: const Locale('ar', 'SA'),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  void _saveHaircut() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار خدمة واحدة على الأقل')),
        );
        return;
      }

      final received = double.tryParse(_receivedController.text) ?? 0.0;
      final price = received;
      final nowStr = DateTime.now().toIso8601String();

      final newHaircut = Haircut(
        id: widget.haircut?.id,
        operationNumber: _opNumberController.text.trim(),
        date: _dateController.text.trim(),
        time: _timeController.text.trim(),
        price: price,
        amountReceived: received,
        notes: _notesController.text.trim(),
        createdAt: widget.haircut?.createdAt ?? nowStr,
        updatedAt: nowStr,
        services: _selectedServices,
      );

      final provider = Provider.of<HaircutProvider>(context, listen: false);

      try {
        if (widget.haircut == null) {
          await provider.addHaircut(newHaircut);
        } else {
          await provider.updateHaircut(newHaircut);
        }
        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableServices = Provider.of<HaircutProvider>(context).services;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.haircut == null ? 'إضافة حلاقة' : 'تعديل حلاقة'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Operation Number
              TextFormField(
                controller: _opNumberController,
                decoration: const InputDecoration(
                  labelText: 'رقم العملية',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                ),
                validator: (v) => v!.isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),

              // Date and Time (12-hour AM/PM with picker and editability)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: false,
                      decoration: InputDecoration(
                        labelText: 'التاريخ',
                        prefixIcon: const Icon(Icons.calendar_today, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.date_range, size: 20),
                          tooltip: 'اختيار التاريخ من التقويم',
                          onPressed: () => _selectDate(context),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      readOnly: false,
                      decoration: InputDecoration(
                        labelText: 'الوقت (12 ساعة AM/PM)',
                        prefixIcon: const Icon(Icons.access_time, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.schedule, size: 20),
                          tooltip: 'تعديل الوقت من الساعة',
                          onPressed: () => _selectTime(context),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Financial inputs: Amount Received
              TextFormField(
                controller: _receivedController,
                decoration: const InputDecoration(
                  labelText: 'المبلغ المستلم',
                  prefixIcon: Icon(Icons.payments),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (v) {
                  if (v == null || v.isEmpty) return 'الرجاء إدخال المبلغ المستلم';
                  if (double.tryParse(v) == null) return 'قيمة غير صالحة';
                  return null;
                },
              ),

              const SizedBox(height: 24),
              const Text('الخدمات:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // Multi-select Checkboxes
              ...availableServices.map((service) {
                final isSelected = _selectedServices.any((s) => s.id == service.id);
                return CheckboxListTile(
                  title: Text(service.name),
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedServices.add(service);
                      } else {
                        _selectedServices.removeWhere((s) => s.id == service.id);
                      }
                    });
                  },
                );
              }),

              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة عن الزبون (اختياري)',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('حفظ الحلاقة', style: TextStyle(fontSize: 18)),
                  onPressed: _saveHaircut,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
