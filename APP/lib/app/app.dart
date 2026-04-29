import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router.dart';
import '../shared/services/locale_provider.dart';

class MamitasApp extends StatelessWidget {
  final LocaleProvider localeProvider;

  const MamitasApp({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return LocaleContainer(
      provider: localeProvider,
      child: ListenableBuilder(
        listenable: localeProvider,
        builder: (context, _) {
          return MaterialApp.router(
            title: 'Thermommatter AI',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF673AB7), // Morado profundo
                primary: const Color(0xFF673AB7),
                secondary: const Color(0xFF1976D2), // Azul vibrante
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              scaffoldBackgroundColor: Colors.transparent,
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                titleTextStyle: TextStyle(
                  color: Color(0xFF311B92), // Morado oscuro
                  fontSize: 24, // Título más grande
                  fontWeight: FontWeight.bold,
                ),
                iconTheme: IconThemeData(color: Color(0xFF673AB7), size: 28),
              ),
              textTheme: const TextTheme(
                headlineMedium: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF311B92),
                ),
                titleLarge: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            locale: localeProvider.locale,
            supportedLocales: const [
              Locale('es'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: appRouter,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Color(0xFFE8EAF6)],
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.35, // Aumentado para que se vea mejor
                      child: Image.asset(
                        'assets/Iconos/pantalla.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (child != null) child,
                ],
              );
            },
          );
        },
      ),
    );
  }
}
