// lib/ui/recurring/views/recurring_screen.dart

import 'package:flutter/material.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recorrentes')),
      body: const Center(
        child: Text('Despesas Recorrentes — próxima iteração'),
      ),
    );
  }
}
