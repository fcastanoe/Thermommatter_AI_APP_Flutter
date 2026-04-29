import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import '../../../shared/services/locale_provider.dart';
import '../../../shared/services/localization_service.dart';

class DatabaseScreen extends StatefulWidget {
  final String currentPath;
  final String? title;

  const DatabaseScreen({
    super.key, 
    this.currentPath = 'assets/Database',
    this.title,
  });

  @override
  State<DatabaseScreen> createState() => _DatabaseScreenState();
}

class _DatabaseScreenState extends State<DatabaseScreen> {
  List<String> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final manifest = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> assetsMap = json.decode(manifest);
      final String prefix = widget.currentPath.endsWith('/') ? widget.currentPath : '${widget.currentPath}/';
      
      final Set<String> uniqueSegments = {};
      for (var path in assetsMap.keys) {
        if (path.startsWith(prefix)) {
          final relativePath = path.substring(prefix.length);
          final segments = relativePath.split('/');
          if (segments.isNotEmpty) uniqueSegments.add(segments[0]);
        }
      }

      final List<String> items = uniqueSegments.toList();
      items.sort((a, b) {
        final numA = int.tryParse(a.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final numB = int.tryParse(b.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        if (numA != numB) return numA.compareTo(numB);
        return a.compareTo(b);
      });

      if (mounted) setState(() { _items = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleProvider.of(context).locale.languageCode;
    String tr(String key) => LocalizationService.translate(lang, key);
    final String displayTitle = widget.title ?? tr('database');

    return Scaffold(
      appBar: AppBar(
        title: Text(displayTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => GoRouter.of(context).go('/home'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(child: Text(tr('no_patients')))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  itemCount: _items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final name = _items[i];
                    final fullPath = '${widget.currentPath}/$name';
                    final isImage = name.toLowerCase().endsWith('.png') || name.toLowerCase().endsWith('.jpg') || name.toLowerCase().endsWith('.jpeg');
                    return Card(
                      color: Colors.white.withOpacity(0.8),
                      child: ListTile(
                        leading: Icon(isImage ? Icons.image : Icons.folder, 
                          color: isImage ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.primary),
                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _handleTap(context, fullPath, name, isImage),
                      ),
                    );
                  },
                ),
    );
  }

  void _handleTap(BuildContext context, String path, String name, bool isImage) {
    if (isImage) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => _AssetImageViewer(path: path, title: name)));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => DatabaseScreen(currentPath: path, title: name)));
    }
  }
}

class _AssetImageViewer extends StatelessWidget {
  final String path;
  final String title;
  const _AssetImageViewer({required this.path, required this.title});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: Text(title), backgroundColor: Colors.black, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: InteractiveViewer(child: Image.asset(path, fit: BoxFit.contain))),
    );
  }
}
