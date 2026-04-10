// lib/ui/categories/views/categories_screen.dart

import 'package:flutter/material.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categorias')),
      body: const Center(
        child: Text('Tela de Categorias — próxima iteração'),
      ),
    );
  }
}
