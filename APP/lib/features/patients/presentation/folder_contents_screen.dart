import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class FolderContentsScreen extends StatefulWidget {
  final String folderPath;
  final String folderName;

  const FolderContentsScreen({
    super.key,
    required this.folderPath,
    required this.folderName,
  });

  @override
  State<FolderContentsScreen> createState() => _FolderContentsScreenState();
}

class _FolderContentsScreenState extends State<FolderContentsScreen> {
  List<FileSystemEntity> _items = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    final dir = Directory(widget.folderPath);
    if (dir.existsSync()) {
      setState(() {
        _items = dir.listSync()
          ..sort((a, b) => a.path.compareTo(b.path));
      });
    }
  }

  void _openFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    
    if (['png', 'jpg', 'jpeg'].contains(ext)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(file.path.split(Platform.pathSeparator).last)),
            body: Center(
              child: InteractiveViewer(
                child: Image.file(file),
              ),
            ),
          ),
        ),
      );
    } else if (ext == 'json') {
      try {
        final content = file.readAsStringSync();
        final Map<String, dynamic> data = jsonDecode(content);
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('Temperaturas')),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: data.entries.map((e) => ListTile(
                  title: Text(e.key),
                  trailing: Text('${(e.value as num).toStringAsFixed(1)} °C'),
                )).toList(),
              ),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error leyendo JSON: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formato de archivo no soportado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
      ),
      body: _items.isEmpty
          ? const Center(child: Text('La carpeta está vacía'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                final isDir = item is Directory;
                final name = item.path.split(Platform.pathSeparator).last;

                return ListTile(
                  leading: Icon(
                    isDir ? Icons.folder : Icons.insert_drive_file,
                    color: isDir ? Colors.amber : Colors.blue,
                  ),
                  title: Text(name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    if (isDir) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FolderContentsScreen(
                            folderPath: item.path,
                            folderName: name,
                          ),
                        ),
                      );
                    } else {
                      _openFile(item as File);
                    }
                  },
                );
              },
            ),
    );
  }
}
