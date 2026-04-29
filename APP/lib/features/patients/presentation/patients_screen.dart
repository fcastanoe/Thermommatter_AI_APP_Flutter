import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/storage/patient_storage.dart';
import '../../../shared/models/patient.dart';
import 'patient_folders_screen.dart';

import '../../../shared/services/locale_provider.dart';
import '../../../shared/services/localization_service.dart';

class PatientsScreen extends StatefulWidget {
  const PatientsScreen({super.key});

  @override
  State<PatientsScreen> createState() => _PatientsScreenState();
}

class _PatientsScreenState extends State<PatientsScreen> {
  final _storage = PatientStorage();
  List<Patient> _patients = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final patients = await _storage.loadAll();
    setState(() {
      _patients = patients;
      _loading = false;
    });
  }

  Future<void> _deletePatient(Patient patient, String lang) async {
    String tr(String key) => LocalizationService.translate(lang, key);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('delete_patient')),
        content: Text('${tr('confirm_delete')} (${patient.first} ${patient.last})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _storage.delete(patient);
      _loadPatients();
    }
  }

  void _showOptions(Patient patient, String lang) {
    String tr(String key) => LocalizationService.translate(lang, key);
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('${patient.first} ${patient.last}'),
              subtitle: Text(
                '${tr('age')}: ${patient.age} · Peso: ${patient.weight} kg · Estatura: ${patient.height} cm',
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(tr('edit_patient').split(' ')[0]), // "Editar"
              onTap: () {
                Navigator.pop(ctx);
                context.push('/patients/edit', extra: patient).then((_) => _loadPatients());
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(tr('delete'), style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _deletePatient(patient, lang);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleProvider.of(context).locale.languageCode;
    String tr(String key) => LocalizationService.translate(lang, key);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('patients')),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => GoRouter.of(context).go('/home'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(tr('no_patients')),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _patients.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final p = _patients[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text('${p.first[0]}${p.last[0]}')),
                      title: Text('${p.first} ${p.last}'),
                      subtitle: Text('${tr('age')}: ${p.age} | Peso: ${p.weight} kg | Estatura: ${p.height} cm'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PatientFoldersScreen(patient: p),
                          ),
                        );
                      },
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () => _showOptions(p, lang),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/patients/new').then((_) => _loadPatients()),
        icon: const Icon(Icons.add),
        label: Text(tr('new_patient')),
      ),
    );
  }
}
