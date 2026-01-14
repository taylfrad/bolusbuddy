import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/screens/capture_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: BolusBuddyApp(),
    ),
  );
}

class BolusBuddyApp extends StatelessWidget {
  const BolusBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BolusBuddy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const CaptureScreen(),
    );
  }
}
