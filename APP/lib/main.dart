import 'package:flutter/material.dart';
import 'app/app.dart';

import 'shared/services/locale_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final localeProvider = LocaleProvider();
  runApp(MamitasApp(localeProvider: localeProvider));
}
