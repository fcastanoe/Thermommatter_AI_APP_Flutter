import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../services/ocr_service.dart';
import '../services/segmentation_service.dart';
import '../services/registration_service.dart';
import '../../../shared/services/locale_provider.dart';
import '../../../shared/services/localization_service.dart';

enum _AnalysisState { idle, imageSelected, running, done, error }

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  _AnalysisState _state = _AnalysisState.idle;
  File? _selectedImage;
  final _maxTempCtrl = TextEditingController();
  final _minTempCtrl = TextEditingController();
  bool _tempRangeWarning = false;

  @override
  void dispose() {
    _maxTempCtrl.dispose();
    _minTempCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _selectedImage = File(picked.path);
      _state = _AnalysisState.imageSelected;
      _maxTempCtrl.clear();
      _minTempCtrl.clear();
      _tempRangeWarning = false;
    });

    try {
      final range = await OcrService.extractVisibleTemperatureRange(picked.path);
      if (range != null && mounted) {
        setState(() {
          _minTempCtrl.text = range.minTemp.toString();
          _maxTempCtrl.text = range.maxTemp.toString();
          _validateTemps();
        });
      }
    } catch (e) {
      print('OCR skip error: $e');
    }
  }

  bool _validateTemps() {
    final max = double.tryParse(_maxTempCtrl.text);
    final min = double.tryParse(_minTempCtrl.text);
    if (max == null || min == null) return false;
    if (max >= 15 && max <= 40 && min >= 15 && min <= 40) {
      setState(() => _tempRangeWarning = false);
      return true;
    }
    setState(() => _tempRangeWarning = true);
    return false;
  }

  Future<void> _startAnalysis() async {
    if (!_validateTemps()) return;
    setState(() => _state = _AnalysisState.running);

    try {
      final outDir = await getApplicationDocumentsDirectory();
      final maskPath = await SegmentationService.processAndSaveMask(
        _selectedImage!.path,
        outDir.path,
      );
      if (maskPath == null) throw Exception('Falló la generación de la máscara');

      final result = await RegistrationService.runRegistration(
        imagePath: _selectedImage!.path,
        maskPath: maskPath,
        minTemp: double.parse(_minTempCtrl.text),
        maxTemp: double.parse(_maxTempCtrl.text),
        outputDir: outDir.path,
      );

      if (mounted) {
        setState(() => _state = _AnalysisState.done);
        context.push('/analysis/result', extra: {
          'imagePath': result['derm_overlay_png'] as String,
          'bwImagePath': result['derm_bw_png'] as String,
          'originalImagePath': _selectedImage!.path,
          'maxTemp': _maxTempCtrl.text,
          'minTemp': _minTempCtrl.text,
          'tempsJson': result['temps_json'],
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state = _AnalysisState.error);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleProvider.of(context).locale.languageCode;
    String tr(String key) => LocalizationService.translate(lang, key);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('analysis')),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => GoRouter.of(context).go('/home'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 260,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.contain),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_photo_alternate_outlined, size: 64, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(tr('select_image'), style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: Text(tr('select_image')),
            ),
            if (_state != _AnalysisState.idle) ...[
              const SizedBox(height: 24),
              const Text('Rango térmico (°C)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _maxTempCtrl,
                      decoration: InputDecoration(
                        labelText: tr('max_temp'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.thermostat, color: Colors.red),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _validateTemps(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _minTempCtrl,
                      decoration: InputDecoration(
                        labelText: tr('min_temp'),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.thermostat, color: Colors.blue),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (_) => _validateTemps(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_state == _AnalysisState.running)
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text('${tr('processing')}...'),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: _startAnalysis,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(tr('run_analysis')),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
