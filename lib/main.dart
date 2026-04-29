import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/login.dart';

void main() {
  runApp(const PJobsApp());
}

class PJobsApp extends StatelessWidget {
  const PJobsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PJobs Express',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Usa o tema que separamos
      home: const LoginScreen(),
    );
  }
}
