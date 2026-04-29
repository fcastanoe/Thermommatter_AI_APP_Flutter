import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/services/locale_provider.dart';
import '../shared/services/localization_service.dart';

class ShellLayout extends StatelessWidget {
  const ShellLayout({super.key, required this.navigationShell});
  
  final StatefulNavigationShell navigationShell;

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = LocaleProvider.of(context).locale.languageCode;
    String tr(String key) => LocalizationService.translate(lang, key);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: navigationShell.currentIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color(0xFF1565C0),
          unselectedItemColor: Colors.grey,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.help_outline),
              activeIcon: const Icon(Icons.help),
              label: tr('help'),
            ),
            BottomNavigationBarItem(
              icon: Image.asset('assets/Iconos/icono_mamitas.png', width: 24, height: 24, color: Colors.grey),
              activeIcon: Image.asset('assets/Iconos/icono_mamitas.png', width: 28, height: 28),
              label: tr('home'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: tr('settings'),
            ),
          ],
        ),
      ),
    );
  }
}
