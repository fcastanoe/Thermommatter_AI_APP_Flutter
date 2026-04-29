import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

class ChartScreen extends StatefulWidget {
  final String patientDir;

  const ChartScreen({super.key, required this.patientDir});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final List<Color> _colors = [
    Colors.red, Colors.green, Colors.blue, Colors.orange,
    Colors.purple, Colors.teal, Colors.pink, Colors.lime,
    Colors.brown, Colors.cyan
  ];

  Map<String, List<FlSpot>> _seriesMap = {};
  Map<String, bool> _visibilityMap = {};
  List<String> _xLabels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tempDir = Directory('${widget.patientDir}/temperaturas');
    if (!await tempDir.exists()) {
      setState(() => _loading = false);
      return;
    }

    final dirs = tempDir.listSync().whereType<Directory>().toList();
    // Ordenar por el número de tX (ej. t0, t1, t10)
    dirs.sort((a, b) {
      final nameA = a.path.split(Platform.pathSeparator).last;
      final nameB = b.path.split(Platform.pathSeparator).last;
      final numA = int.tryParse(nameA.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      final numB = int.tryParse(nameB.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return numA.compareTo(numB);
    });

    final Map<String, List<FlSpot>> series = {};
    final List<String> labels = [];

    for (int i = 0; i < dirs.length; i++) {
      final d = dirs[i];
      final name = d.path.split(Platform.pathSeparator).last;
      labels.add(name);

      final jsonFile = File('${d.path}/data.json');
      if (jsonFile.existsSync()) {
        final content = await jsonFile.readAsString();
        final Map<String, dynamic> data = jsonDecode(content);

        data.forEach((key, value) {
          final temp = (value as num).toDouble();
          if (!series.containsKey(key)) {
            series[key] = [];
          }
          series[key]!.add(FlSpot(i.toDouble(), temp));
        });
      }
    }

    setState(() {
      _seriesMap = series;
      for (var key in series.keys) {
        _visibilityMap[key] = true;
      }
      _xLabels = labels;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_seriesMap.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Evolución de Temperaturas')),
        body: const Center(child: Text('No hay datos suficientes para graficar.')),
      );
    }

    // Preparar datos para fl_chart
    final List<LineChartBarData> lineBarsData = [];
    int colorIdx = 0;
    
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    _seriesMap.forEach((key, spots) {
      if (_visibilityMap[key] == true) {
        for (var s in spots) {
          if (s.y < minY) minY = s.y;
          if (s.y > maxY) maxY = s.y;
        }

        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: _colors[colorIdx % _colors.length],
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
          ),
        );
      }
      colorIdx++;
    });

    if (minY == double.infinity) minY = 0;
    if (maxY == double.negativeInfinity) maxY = 40;

    return Scaffold(
      appBar: AppBar(title: const Text('Evolución de Temperaturas')),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0, left: 16.0, top: 24.0, bottom: 16.0),
              child: LineChart(
                LineChartData(
                  lineBarsData: lineBarsData,
                  minY: minY - 1,
                  maxY: maxY + 1,
                  minX: 0,
                  maxX: max(0, _xLabels.length - 1).toDouble(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < _xLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(_xLabels[idx], style: const TextStyle(fontSize: 12)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 12));
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  lineTouchData: const LineTouchData(
                    handleBuiltInTouches: true,
                  ),
                ),
              ),
            ),
          ),
          const Divider(),
          Expanded(
            flex: 2,
            child: ListView(
              children: _seriesMap.keys.toList().asMap().entries.map((entry) {
                final idx = entry.key;
                final key = entry.value;
                return CheckboxListTile(
                  title: Text(key, style: TextStyle(color: _colors[idx % _colors.length], fontWeight: FontWeight.bold)),
                  value: _visibilityMap[key],
                  onChanged: (bool? val) {
                    setState(() {
                      _visibilityMap[key] = val ?? true;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
