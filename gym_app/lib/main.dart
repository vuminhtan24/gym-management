import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/member_provider.dart';
import 'providers/package_provider.dart';
import 'providers/trainer_provider.dart';
import 'providers/pt_schedule_provider.dart';
import 'providers/class_provider.dart';
import 'providers/staff_provider.dart';
import 'providers/report_provider.dart';
import 'screens/auth_gate.dart';

void main() {
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MemberProvider()),
        ChangeNotifierProvider(create: (_) => PackageProvider()),
        ChangeNotifierProvider(create: (_) => TrainerProvider()),
        ChangeNotifierProvider(create: (_) => PTScheduleProvider()),
        ChangeNotifierProvider(create: (_) => ClassProvider()),
        ChangeNotifierProvider(create: (_) => StaffProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
      ],
      child: MaterialApp(
        title: 'Gym Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
