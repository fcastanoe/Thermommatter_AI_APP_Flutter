import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../shared/services/locale_provider.dart';
import '../shared/services/localization_service.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = LocaleProvider.of(context).locale.languageCode;
    String tr(String key) => LocalizationService.translate(lang, key);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thermommatter AI'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      extendBodyBehindAppBar: true,
      body: Padding(
        padding: const EdgeInsets.only(top: 100.0, left: 16.0, right: 16.0, bottom: 16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _DashboardCard(
              title: tr('patients'), 
              imagePath: 'assets/Iconos/ic_patient.png', 
              onTap: () => context.push('/patients')
            ),
            _DashboardCard(
              title: tr('analysis'), 
              imagePath: 'assets/Iconos/ic_analysis.png', 
              onTap: () => context.push('/analysis')
            ),
            _DashboardCard(
              title: tr('results'), 
              imagePath: 'assets/Iconos/ic_results.png', 
              onTap: () => context.push('/results')
            ),
            _DashboardCard(
              title: tr('database'), 
              imagePath: 'assets/Iconos/ic_dataset.png', 
              onTap: () => context.push('/database')
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final VoidCallback onTap;

  const _DashboardCard({required this.title, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, width: 64, height: 64),
            const SizedBox(height: 12),
            Text(title, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
