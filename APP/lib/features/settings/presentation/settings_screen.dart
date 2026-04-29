import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/services/locale_provider.dart';
import '../../../shared/services/localization_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final localeProvider = LocaleProvider.of(context);
    final lang = localeProvider.locale.languageCode;
    
    String tr(String key) => LocalizationService.translate(lang, key);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('settings')),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => GoRouter.of(context).go('/home'),
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(tr('language'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          ),
          RadioListTile<String>(
            title: const Text('Español'),
            value: 'es',
            groupValue: lang,
            onChanged: (v) => localeProvider.setLocale(const Locale('es')),
          ),
          RadioListTile<String>(
            title: const Text('English'),
            value: 'en',
            groupValue: lang,
            onChanged: (v) => localeProvider.setLocale(const Locale('en')),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(tr('data'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(tr('clear_data'), style: const TextStyle(color: Colors.red)),
            subtitle: Text(tr('clear_data_desc')),
            onTap: _clearData,
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(tr('about'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Mamitas AI'),
            subtitle: Text('v1.0.0 — GCPDS, Universidad Nacional de Colombia'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearData() async {
    final localeProvider = LocaleProvider.of(context);
    final lang = localeProvider.locale.languageCode;
    String tr(String key) => LocalizationService.translate(lang, key);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('confirm_delete')),
        content: Text(tr('clear_data_desc')),
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
      final prefs = await SharedPreferences.getInstance();
      final currentLang = prefs.getString('lang');
      await prefs.clear();
      if (currentLang != null) await prefs.setString('lang', currentLang);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('results'))), // Placeholder or specific key
        );
      }
    }
  }
}
