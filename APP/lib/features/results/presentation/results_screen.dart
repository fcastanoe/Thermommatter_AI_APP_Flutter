import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import 'package:fl_chart/fl_chart.dart';
import '../../../services/storage/patient_storage.dart';
import '../../../shared/models/patient.dart';
import '../../../shared/services/locale_provider.dart';
import '../../../shared/services/localization_service.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _storage = PatientStorage();
  List<Patient> _patients = [];
  Patient? _selected;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final patients = await _storage.loadAll();
    setState(() {
      _patients = patients;
      _loading = false;
    });
  }

  void _selectPatient(String lang) {
    String tr(String key) => LocalizationService.translate(lang, key);
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(tr('select_patient')),
        children: _patients.map((p) {
          return SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _selected = p);
            },
            child: ListTile(
              leading: CircleAvatar(child: Text('${p.first[0]}${p.last[0]}')),
              title: Text('${p.first} ${p.last}'),
              subtitle: Text('${p.age} ${tr('age').toLowerCase()}'),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleProvider.of(context).locale.languageCode;
    String tr(String key) => LocalizationService.translate(lang, key);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('results')),
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
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: FilledButton.icon(
                        onPressed: () => _selectPatient(lang),
                        icon: const Icon(Icons.person_search),
                        label: Text(_selected == null
                            ? tr('select_patient')
                            : '${_selected!.first} ${_selected!.last}'),
                      ),
                    ),
                    if (_selected != null)
                      Expanded(
                        child: _PatientEvolutionView(
                          key: ValueKey(_selected!.folderName),
                          patient: _selected!,
                          lang: lang,
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _PatientEvolutionView extends StatefulWidget {
  final Patient patient;
  final String lang;
  const _PatientEvolutionView({super.key, required this.patient, required this.lang});

  @override
  State<_PatientEvolutionView> createState() => _PatientEvolutionViewState();
}

class _PatientEvolutionViewState extends State<_PatientEvolutionView> {
  String? _gifPath;
  bool _generatingGif = true;
  bool _gifError = false;
  Map<String, List<FlSpot>> _seriesMap = {};
  List<String> _xLabels = [];
  Map<String, bool> _visibilityMap = {};
  bool _loadingChart = true;

  final List<Color> _colors = [
    Colors.red, Colors.green, Colors.blue, Colors.orange,
    Colors.purple, Colors.teal, Colors.pink, Colors.lime,
    Colors.brown, Colors.cyan
  ];

  @override
  void initState() {
    super.initState();
    _generateGif();
    _loadChartData();
  }

  Future<void> _generateGif() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final patientDir = Directory('${docDir.path}/Pacientes/${widget.patient.folderName}');
      final imgsDir = Directory('${patientDir.path}/imagenes');
      
      if (!await imgsDir.exists()) {
        setState(() { _generatingGif = false; _gifError = true; });
        return;
      }

      final folders = imgsDir.listSync().whereType<Directory>().toList();
      folders.sort((a, b) {
        final nameA = a.path.split(Platform.pathSeparator).last;
        final nameB = b.path.split(Platform.pathSeparator).last;
        final numA = int.tryParse(nameA.substring(1)) ?? 0;
        final numB = int.tryParse(nameB.substring(1)) ?? 0;
        return numA.compareTo(numB);
      });

      if (folders.isEmpty) {
        setState(() { _generatingGif = false; _gifError = true; });
        return;
      }

      final cachePath = '${patientDir.path}/evolucion.gif';
      img.Image? animation;
      for (var folder in folders) {
        final imgFile = File('${folder.path}/imagen.png');
        if (await imgFile.exists()) {
          final bytes = await imgFile.readAsBytes();
          final frame = img.decodeImage(bytes);
          if (frame != null) {
            frame.frameDuration = 1000;
            if (animation == null) {
              animation = frame;
            } else {
              animation.addFrame(frame);
            }
          }
        }
      }

      if (animation == null) {
        setState(() { _generatingGif = false; _gifError = true; });
        return;
      }

      final gifBytes = img.encodeGif(animation);
      if (gifBytes != null) {
        await File(cachePath).writeAsBytes(gifBytes);
        if (mounted) {
          setState(() {
            _gifPath = cachePath;
            _generatingGif = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() { _generatingGif = false; _gifError = true; });
    }
  }

  Future<void> _loadChartData() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final patientDir = Directory('${docDir.path}/Pacientes/${widget.patient.folderName}');
      final tempDir = Directory('${patientDir.path}/temperaturas');
      
      if (!await tempDir.exists()) {
        setState(() => _loadingChart = false);
        return;
      }

      final dirs = tempDir.listSync().whereType<Directory>().toList();
      dirs.sort((a, b) {
        final nameA = a.path.split(Platform.pathSeparator).last;
        final nameB = b.path.split(Platform.pathSeparator).last;
        final numA = int.tryParse(nameA.substring(1)) ?? 0;
        final numB = int.tryParse(nameB.substring(1)) ?? 0;
        return numA.compareTo(numB);
      });

      final Map<String, List<FlSpot>> series = {};
      final List<String> labels = [];

      for (int i = 0; i < dirs.length; i++) {
        final d = dirs[i];
        final name = d.path.split(Platform.pathSeparator).last;
        labels.add(name);

        final jsonFile = File('${d.path}/data.json');
        if (await jsonFile.exists()) {
          final content = await jsonFile.readAsString();
          final Map<String, dynamic> data = jsonDecode(content);
          data.forEach((key, value) {
            final temp = (value as num).toDouble();
            if (!series.containsKey(key)) series[key] = [];
            series[key]!.add(FlSpot(i.toDouble(), temp));
          });
        }
      }

      if (mounted) {
        setState(() {
          _seriesMap = series;
          _xLabels = labels;
          for (var k in series.keys) _visibilityMap[k] = true;
          _loadingChart = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingChart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    String tr(String key) => LocalizationService.translate(widget.lang, key);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text('${tr('thermal_evolution')} (GIF)', 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              if (_generatingGif)
                const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
              else if (_gifError || _gifPath == null)
                const SizedBox(height: 200, child: Center(child: Text('Not enough data')))
              else
                GestureDetector(
                  onTap: () {
                    final old = _gifPath;
                    setState(() => _gifPath = null);
                    Future.delayed(const Duration(milliseconds: 50), () {
                      if (mounted) setState(() => _gifPath = old);
                    });
                  },
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.file(
                      File(_gifPath!),
                      fit: BoxFit.contain,
                      key: ValueKey(_gifPath),
                    ),
                  ),
                ),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Tap to restart animation.', 
                  style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(tr('temperature_chart'), 
                  style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                if (_loadingChart)
                  const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                else if (_seriesMap.isEmpty)
                  const SizedBox(height: 200, child: Center(child: Text('No data recorded')))
                else ...[
                  SizedBox(height: 250, child: _buildChart()),
                  const SizedBox(height: 16),
                  const Text('Dermatomas:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _seriesMap.keys.map((k) {
                      final idx = _seriesMap.keys.toList().indexOf(k);
                      final color = _colors[idx % _colors.length];
                      return FilterChip(
                        label: Text(k, style: const TextStyle(fontSize: 10)),
                        selected: _visibilityMap[k] ?? false,
                        selectedColor: color.withOpacity(0.2),
                        checkmarkColor: color,
                        onSelected: (val) => setState(() => _visibilityMap[k] = val),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChart() {
    final List<LineChartBarData> bars = [];
    double minY = 40;
    double maxY = 0;
    int i = 0;
    _seriesMap.forEach((key, spots) {
      if (_visibilityMap[key] == true) {
        for (var s in spots) {
          if (s.y < minY) minY = s.y;
          if (s.y > maxY) maxY = s.y;
        }
        bars.add(LineChartBarData(
          spots: spots,
          color: _colors[i % _colors.length],
          barWidth: 3,
          isCurved: false,
          dotData: const FlDotData(show: true),
        ));
      }
      i++;
    });
    if (minY > maxY) { minY = 20; maxY = 40; } else { minY -= 1; maxY += 1; }
    return LineChart(
      LineChartData(
        lineBarsData: bars,
        minY: minY,
        maxY: maxY,
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 35, getTitlesWidget: (v, m) => Text('${v.toInt()}°', style: const TextStyle(fontSize: 10)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1, getTitlesWidget: (v, m) {
            final idx = v.toInt();
            if (idx >= 0 && idx < _xLabels.length) return Text(_xLabels[idx], style: const TextStyle(fontSize: 10));
            return const SizedBox();
          })),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
        lineTouchData: const LineTouchData(handleBuiltInTouches: true),
      ),
    );
  }
}
