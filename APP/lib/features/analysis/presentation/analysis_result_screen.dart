// analysis_result_screen.dart
//
// CAMBIOS v2 (solo visualización de depuración):
// ────────────────────────────────────────────────
// 1. La pantalla ahora muestra la imagen B&N con contornos rojos del
//    registro no rígido (pasada como 'imagePath'). Esto permite verificar
//    visualmente si el registro se realizó correctamente antes de pasar
//    a la visualización final con el mapa de colores.
//
// 2. Se añade un banner informativo en la parte superior indicando que es
//    la vista de depuración del registro no rígido.
//
// 3. Las temperaturas por dermatoma se siguen mostrando debajo de la imagen
//    en tarjetas desplazables horizontalmente, igual que antes.
//
// 4. El botón "Guardar" permanece con el mensaje "Próximamente" hasta que
//    se integre la lógica de pacientes.
//
// 5. Se añade el parámetro opcional 'originalImagePath' para comparación.

import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../../services/storage/patient_storage.dart';
import '../../../shared/models/patient.dart';
import '../../patients/presentation/new_patient_screen.dart';

class AnalysisResultScreen extends StatefulWidget {
  /// Ruta a la imagen B&N con contornos rojos del registro no rígido.
  final String imagePath;

  /// Ruta a la imagen B&N con contornos rojos del registro no rígido.
  final String? bwImagePath;

  /// Ruta a la imagen original (opcional, para comparar).
  final String? originalImagePath;

  final String maxTemp;
  final String minTemp;
  final Map<String, dynamic>? tempsJson;

  const AnalysisResultScreen({
    super.key,
    required this.imagePath,
    this.bwImagePath,
    this.originalImagePath,
    required this.maxTemp,
    required this.minTemp,
    this.tempsJson,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  final PatientStorage _storage = PatientStorage();

  void _onSavePressed() async {
    final patients = await _storage.loadAll();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Guardar Resultados'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_add),
                  title: const Text('Crear paciente nuevo'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _createNewPatientAndSave();
                  },
                ),
                const Divider(),
                if (patients.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay pacientes registrados.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...patients.map((p) => ListTile(
                    leading: const Icon(Icons.person),
                    title: Text('${p.first} ${p.last}'),
                    subtitle: Text('${p.age} años'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _saveToPatient(p);
                    },
                  )).toList(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
          ],
        );
      }
    );
  }

  void _createNewPatientAndSave() async {
    // Usamos el push para ir a NewPatientScreen. Como necesitamos saber si guardó:
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NewPatientScreen()),
    );
    // Después de volver, recargamos y mostramos de nuevo el diálogo, 
    // o podríamos asumir que si se creó, lo guardamos automáticamente en el más reciente.
    // Para simplificar, le pedimos al usuario que pulse Guardar de nuevo, o abrimos el diálogo.
    _onSavePressed();
  }

  void _saveToPatient(Patient patient) async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final patientDir = Directory('${docDir.path}/Pacientes/${patient.folderName}');
      
      // Determinar el siguiente índice de análisis (T0, T1, ...)
      int nextIdx = 0;
      final tempDirBase = Directory('${patientDir.path}/temperaturas');
      if (await tempDirBase.exists()) {
        final dirs = tempDirBase.listSync().whereType<Directory>();
        for (var d in dirs) {
          final name = d.path.split(Platform.pathSeparator).last;
          if (name.toUpperCase().startsWith('T')) {
            final idx = int.tryParse(name.substring(1));
            if (idx != null && idx >= nextIdx) {
              nextIdx = idx + 1;
            }
          }
        }
      }
      
      final tx = 'T$nextIdx';
      
      // 1. Guardar imagen coloreada en imagenes/Tx/
      final coloredFile = File(widget.imagePath);
      final coloredDest = File('${patientDir.path}/imagenes/$tx/imagen.png');
      await coloredDest.create(recursive: true);
      await coloredFile.copy(coloredDest.path);

      // 2. Guardar imagen B&N con contornos rojos en registros/Tx/
      if (widget.bwImagePath != null) {
        final bwFile = File(widget.bwImagePath!);
        final bwDest = File('${patientDir.path}/registros/$tx/imagen.png');
        await bwDest.create(recursive: true);
        await bwFile.copy(bwDest.path);
      }
      
      // 3. Guardar temperaturas JSON en temperaturas/Tx/
      if (widget.tempsJson != null) {
        final jsonFile = File('${patientDir.path}/temperaturas/$tx/data.json');
        await jsonFile.create(recursive: true);
        await jsonFile.writeAsString(jsonEncode(widget.tempsJson));
      }

      // La carpeta 'grafica/' no requiere subcarpetas Tx. Se llenará o se 
      // usará al generar la gráfica general de la evolución.
      final graficaDir = Directory('${patientDir.path}/grafica');
      if (!await graficaDir.exists()) await graficaDir.create(recursive: true);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardado exitosamente en ${patient.first}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados del Análisis'),
      ),
      body: Column(
        children: [
          // ── Imagen principal: Plantillas a color ──────────────────────
          Expanded(
            child: InteractiveViewer(
              child: Image.file(
                File(widget.imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, _) => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No se pudo cargar la imagen de registro.',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Panel inferior: temperaturas + botones ────────────────────────
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Chips de temperatura global
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _TempChip(
                        label: 'Máx', value: widget.maxTemp, color: Colors.red),
                    _TempChip(
                        label: 'Mín', value: widget.minTemp, color: Colors.blue),
                  ],
                ),
                const SizedBox(height: 8),

                if (widget.tempsJson != null && widget.tempsJson!.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Temperaturas por dermatoma (°C):',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Tarjetas desplazables horizontalmente por zona
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.tempsJson!.keys.length,
                      itemBuilder: (ctx, i) {
                        final String k = widget.tempsJson!.keys.elementAt(i);
                        // La temperatura puede venir como double o int
                        final double val =
                            (widget.tempsJson![k] as num).toDouble();
                        // Color de la tarjeta: rojo si > 32°C, azul si < 28°C
                        final Color cardColor = val > 32
                            ? Colors.red.shade50
                            : val < 28
                                ? Colors.blue.shade50
                                : Colors.green.shade50;
                        return Card(
                          color: cardColor,
                          margin: const EdgeInsets.all(4),
                          child: Container(
                            width: 110,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  k,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${val.toStringAsFixed(1)} °C',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No se calcularon temperaturas por dermatoma.\n'
                      'Revisa que el registro no rígido sea correcto.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 12),

                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Nueva imagen'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _onSavePressed,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
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
}

// ── Widget auxiliar para mostrar temperatura global ────────────────────────
// (sin cambios respecto a v1)
class _TempChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _TempChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(Icons.thermostat, color: color, size: 18),
      label: Text(
        '$label: $value °C',
        style:
            TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.4)),
    );
  }
}
