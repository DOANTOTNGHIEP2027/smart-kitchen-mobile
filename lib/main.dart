import 'package:flutter/material.dart';

void main() {
  runApp(const SmartKitchenApp());
}

class SmartKitchenApp extends StatelessWidget {
  const SmartKitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Kitchen',
      home: Scaffold(
        appBar: AppBar(title: const Text('Smart Kitchen')),
        body: const Center(
          child: Text('Kitchen control center'),
        ),
      ),
    );
  }
}
