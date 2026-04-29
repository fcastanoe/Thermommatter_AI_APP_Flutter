import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/storage/patient_storage.dart';
import '../../../shared/models/patient.dart';

class NewPatientScreen extends StatefulWidget {
  final Patient? editPatient;
  const NewPatientScreen({super.key, this.editPatient});

  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _storage = PatientStorage();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _lastCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;

  bool get _isEditing => widget.editPatient != null;

  @override
  void initState() {
    super.initState();
    final p = widget.editPatient;
    _nameCtrl = TextEditingController(text: p?.first ?? '');
    _lastCtrl = TextEditingController(text: p?.last ?? '');
    _ageCtrl = TextEditingController(text: p?.age.toString() ?? '');
    _weightCtrl = TextEditingController(text: p?.weight.toString() ?? '');
    _heightCtrl = TextEditingController(text: p?.height.toString() ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lastCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final newPatient = Patient(
      first: _nameCtrl.text.trim(),
      last: _lastCtrl.text.trim(),
      age: int.parse(_ageCtrl.text.trim()),
      weight: double.parse(_weightCtrl.text.trim()),
      height: double.parse(_heightCtrl.text.trim()),
    );

    if (_isEditing) {
      await _storage.rename(widget.editPatient!, newPatient);
    } else {
      await _storage.save(newPatient);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEditing ? 'Paciente actualizado' : 'Paciente guardado')),
      );
      context.pop();
    }
  }

  String? _required(String? val) =>
      val == null || val.trim().isEmpty ? 'Este campo es requerido' : null;

  String? _numValidator(String? val) {
    if (val == null || val.isEmpty) return 'Requerido';
    if (double.tryParse(val) == null) return 'Ingresa un número válido';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Paciente' : 'Nuevo Paciente'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
              validator: _required,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastCtrl,
              decoration: const InputDecoration(labelText: 'Apellido', border: OutlineInputBorder()),
              validator: _required,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ageCtrl,
              decoration: const InputDecoration(labelText: 'Edad (años)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
              validator: _numValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _weightCtrl,
              decoration: const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _numValidator,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _heightCtrl,
              decoration: const InputDecoration(labelText: 'Estatura (cm)', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: _numValidator,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(_isEditing ? 'Guardar cambios' : 'Crear Paciente'),
            ),
          ],
        ),
      ),
    );
  }
}
