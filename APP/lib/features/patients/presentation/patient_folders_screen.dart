import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../../shared/models/patient.dart';
import 'folder_contents_screen.dart';
import 'chart_screen.dart';

class PatientFoldersScreen extends StatelessWidget {
  final Patient patient;

  const PatientFoldersScreen({super.key, required this.patient});

  Future<Directory> _getPatientDir() async {
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/Pacientes/${patient.folderName}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${patient.first} ${patient.last}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Detalles del Paciente'),
                  content: Text('Nombre: ${patient.first} ${patient.last}\nEdad: ${patient.age} años\nPeso: ${patient.weight} kg\nEstatura: ${patient.height} cm'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('OK'),
                    )
                  ],
                ),
              );
            },
          )
        ],
      ),
      body: FutureBuilder<Directory>(
        future: _getPatientDir(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final baseDir = snapshot.data!;
          final folders = ['temperaturas', 'imagenes', 'registros', 'grafica'];

          return ListView.builder(
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folderName = folders[index];
              final isGrafica = folderName == 'grafica';
              return ListTile(
                leading: Icon(
                  isGrafica ? Icons.show_chart : Icons.folder,
                  color: isGrafica ? Colors.purple : Colors.blue,
                ),
                title: Text(folderName.toUpperCase()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  final folderDir = Directory('${baseDir.path}/$folderName');
                  if (!folderDir.existsSync()) {
                    folderDir.createSync(recursive: true);
                  }

                  if (isGrafica) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChartScreen(patientDir: baseDir.path),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FolderContentsScreen(
                          folderPath: folderDir.path,
                          folderName: folderName.toUpperCase(),
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
