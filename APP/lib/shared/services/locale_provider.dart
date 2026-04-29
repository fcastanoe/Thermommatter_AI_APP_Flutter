import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('es');
  bool _isInitialized = false;

  Locale get locale => _locale;
  bool get isInitialized => _isInitialized;

  LocaleProvider() {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? langCode = prefs.getString('lang');
    if (langCode != null) {
      _locale = Locale(langCode);
    } else {
      // Intentar usar el idioma del sistema si no hay preferencia guardada
      final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
      if (systemLocale.languageCode == 'en') {
        _locale = const Locale('en');
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    
    _locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', locale.languageCode);
    notifyListeners();
  }

  static LocaleProvider of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<_LocaleInheritedWidget>()?.provider;
    if (provider == null) throw Exception('LocaleProvider not found in context');
    return provider;
  }
}

class _LocaleInheritedWidget extends InheritedWidget {
  final LocaleProvider provider;
  const _LocaleInheritedWidget({required this.provider, required super.child});

  @override
  bool updateShouldNotify(_LocaleInheritedWidget oldWidget) => true;
}

class LocaleContainer extends StatelessWidget {
  final LocaleProvider provider;
  final Widget child;
  const LocaleContainer({super.key, required this.provider, required this.child});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: provider,
      builder: (context, _) {
        return _LocaleInheritedWidget(
          provider: provider,
          child: child,
        );
      },
    );
  }
}
