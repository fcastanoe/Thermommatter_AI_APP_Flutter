import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../shared/models/patient.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Handles CRUD operations for patients using SharedPreferences.
/// Stores the set of folder names as a JSON-encoded list under "patients".
class PatientStorage {
  static const _setKey = 'patients';

  Future<Set<String>> _getFolders(SharedPreferences prefs) async {
    final raw = prefs.getString(_setKey);
    if (raw == null) return {};
    return (jsonDecode(raw) as List).cast<String>().toSet();
  }

  Future<void> _saveFolders(SharedPreferences prefs, Set<String> folders) async {
    await prefs.setString(_setKey, jsonEncode(folders.toList()));
  }

  Future<List<Patient>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final folders = await _getFolders(prefs);
    final patients = <Patient>[];
    for (final folder in folders) {
      final json = prefs.getString('patient_$folder');
      if (json != null) {
        patients.add(Patient.fromJsonString(json));
      }
    }
    return patients;
  }

  Future<void> save(Patient patient) async {
    final prefs = await SharedPreferences.getInstance();
    final folders = await _getFolders(prefs);
    folders.add(patient.folderName);
    await _saveFolders(prefs, folders);
    await prefs.setString('patient_${patient.folderName}', patient.toJsonString());
    
    // Crear carpetas físicas
    final docDir = await getApplicationDocumentsDirectory();
    final patientDir = Directory('${docDir.path}/Pacientes/${patient.folderName}');
    if (!await patientDir.exists()) {
      await patientDir.create(recursive: true);
    }
    await Directory('${patientDir.path}/temperaturas').create(recursive: true);
    await Directory('${patientDir.path}/imagenes').create(recursive: true);
    await Directory('${patientDir.path}/registros').create(recursive: true);
    await Directory('${patientDir.path}/grafica').create(recursive: true);
  }

  Future<void> delete(Patient patient) async {
    final prefs = await SharedPreferences.getInstance();
    final folders = await _getFolders(prefs);
    folders.remove(patient.folderName);
    await _saveFolders(prefs, folders);
    await prefs.remove('patient_${patient.folderName}');
  }

  Future<void> rename(Patient oldPatient, Patient newPatient) async {
    await delete(oldPatient);
    await save(newPatient);
  }
}
