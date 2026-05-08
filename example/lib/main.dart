import 'package:flutter/material.dart';
import 'package:loading_text_shifter/loading_text_shifter.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LoadingTextShifter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ExampleScreen(),
    );
  }
}

class ExampleScreen extends StatelessWidget {
  const ExampleScreen({super.key});

  static const List<String> _messages = [
    'Loading...',
    'Checking your account...',
    'Getting things ready...',
    'Almost there...',
    'Thanks for your patience...',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: LoadingTextShifter(
          messages: _messages,
          loop: false,
          shiftDuration: const Duration(seconds: 2),
          animationDuration: const Duration(milliseconds: 500),
          height: 120,
          backgroundColor: Colors.white,
          centerTextStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          adjacentTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black54,
          ),
          onShift: (index, message) {
            debugPrint('Shifted to [$index]: $message');
          },
        ),
      ),
    );
  }
}
