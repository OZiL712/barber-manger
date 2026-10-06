import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/haircut_provider.dart';
import '../../../core/models/haircut.dart';
import '../../../core/models/barber_service.dart';

class AddEditHaircutScreen extends StatefulWidget {
  final Haircut? haircut;

  const AddEditHaircutScreen({Key? key, this.haircut}) : super(key: key);

  @override
  _AddEditHaircutScreenState createState() => _AddEditHaircutScreenState();
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
    _timeController = TextEditingController(
      text: widget.haircut?.time ?? DateFormat('HH:mm').format(now),
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
        operationNumber: _opNumberController.text,
        date: _dateController.text,
        time: _timeController.text,
        price: price,
        amountReceived: received,
        notes: _notesController.text,
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
              // Auto-generated but editable fields
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _opNumberController,
                      decoration: const InputDecoration(labelText: 'رقم العملية'),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(labelText: 'التاريخ'),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _timeController,
                      decoration: const InputDecoration(labelText: 'الوقت'),
                      validator: (v) => v!.isEmpty ? 'مطلوب' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Financial inputs (Strict rule: No auto calculation of change)
              TextFormField(
                controller: _receivedController,
                decoration: const InputDecoration(labelText: 'المبلغ المستلم', prefixIcon: Icon(Icons.payments)),
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
              }).toList(),
              
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'ملاحظة عن الزبون (اختياري)'),
                maxLines: 2,
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveHaircut,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16.0)),
                  child: const Text('حفظ', style: TextStyle(fontSize: 18)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
