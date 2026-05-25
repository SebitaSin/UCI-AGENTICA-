import 'package:flutter/material.dart';
import 'screens/camera_screen.dart';

class EndoscopioApp extends StatelessWidget {
  const EndoscopioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Endoscopio USB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00BCD4),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const CameraScreen(),
    );
  }
}
