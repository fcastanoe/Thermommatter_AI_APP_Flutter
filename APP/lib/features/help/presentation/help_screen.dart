import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../shared/services/locale_provider.dart';
import '../../../shared/services/localization_service.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  Future<void> _downloadManual(BuildContext context, String assetName, String lang) async {
    final tr = (String key) => LocalizationService.translate(lang, key);
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('downloading'))),
      );

      final byteData = await rootBundle.load('assets/Docs/$assetName');
      final bytes = byteData.buffer.asUint8List();

      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$assetName');
      await file.writeAsBytes(bytes);

      await OpenFile.open(file.path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('download_success'))),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleProvider.of(context).locale.languageCode;
    final tr = (String key) => LocalizationService.translate(lang, key);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('help')),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => GoRouter.of(context).go('/home'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _HelpSection(
            icon: Icons.people,
            color: Colors.blue,
            title: tr('patients'),
            subtitle: lang == 'es' 
              ? 'Crea, edita y gestiona tus pacientes desde el módulo principal.'
              : 'Create, edit and manage your patients from the main module.',
          ),
          const Divider(),
          _HelpSection(
            icon: Icons.analytics,
            color: Colors.green,
            title: tr('analysis'),
            subtitle: lang == 'es'
              ? 'Selecciona una imagen termográfica e ingresa el rango de temperatura para ejecutar el análisis.'
              : 'Select a thermographic image and enter the temperature range to run the analysis.',
          ),
          const Divider(),
          _HelpSection(
            icon: Icons.receipt_long,
            color: Colors.orange,
            title: tr('results'),
            subtitle: lang == 'es'
              ? 'Visualiza el historial de sesiones de un paciente incluyendo el GIF evolutivo y la gráfica de temperaturas.'
              : 'View a patient\'s session history including the evolutionary GIF and temperature chart.',
          ),
          const Divider(),
          _HelpSection(
            icon: Icons.storage,
            color: Colors.purple,
            title: tr('database'),
            subtitle: lang == 'es'
              ? 'Explora los casos de ejemplo incluidos en la aplicación.'
              : 'Explore the example cases included in the application.',
          ),
          const Divider(),
          const SizedBox(height: 24),
          Text(tr('history'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: Text(tr('download_manual')),
            subtitle: Text(tr('user_manual_desc')),
            onTap: () => _downloadManual(context, 'Guia_de_Usuario_ThermoMater_AI.pdf', lang),
            trailing: const Icon(Icons.download),
          ),
          ListTile(
            leading: const Icon(Icons.description, color: Colors.blueGrey),
            title: Text(tr('download_technical')),
            subtitle: Text(tr('tech_manual_desc')),
            onTap: () => _downloadManual(context, 'Manual_Tecnico_ThermoMater_AI.pdf', lang),
            trailing: const Icon(Icons.download),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _HelpSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
