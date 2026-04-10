// lib/ui/history/views/history_screen.dart

import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: const Center(
        child: Text('Histórico completo — próxima iteração'),
      ),
    );
  }
}
