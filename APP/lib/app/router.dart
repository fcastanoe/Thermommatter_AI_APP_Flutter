import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'shell_layout.dart';
import 'dashboard_screen.dart';
import '../features/patients/presentation/patients_screen.dart';
import '../features/patients/presentation/new_patient_screen.dart';
import '../features/analysis/presentation/analysis_screen.dart';
import '../features/analysis/presentation/analysis_result_screen.dart';
import '../features/results/presentation/results_screen.dart';
import '../features/sample_database/presentation/database_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/help/presentation/help_screen.dart';
import '../shared/models/patient.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/patients',
      builder: (context, state) => const PatientsScreen(),
    ),
    GoRoute(
      path: '/patients/new',
      builder: (context, state) => const NewPatientScreen(),
    ),
    GoRoute(
      path: '/patients/edit',
      builder: (context, state) =>
          NewPatientScreen(editPatient: state.extra as Patient?),
    ),
    GoRoute(
      path: '/analysis',
      builder: (context, state) => const AnalysisScreen(),
    ),
    GoRoute(
      path: '/analysis/result',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return AnalysisResultScreen(
          imagePath: extra['imagePath'] as String,
          bwImagePath: extra['bwImagePath'] as String?,
          originalImagePath: extra['originalImagePath'] as String?,
          maxTemp: extra['maxTemp'] as String,
          minTemp: extra['minTemp'] as String,
          tempsJson: extra['tempsJson'] as Map<String, dynamic>?,
        );
      },
    ),
    GoRoute(
      path: '/results',
      builder: (context, state) => const ResultsScreen(),
    ),
    GoRoute(
      path: '/database',
      builder: (context, state) => const DatabaseScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ShellLayout(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/help',
              builder: (context, state) => const HelpScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const DashboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

