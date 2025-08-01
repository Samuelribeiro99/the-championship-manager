// Exemplo para historico_screen.dart
import 'package:flutter/material.dart';

class TelaHistorico extends StatelessWidget {
  const TelaHistorico({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: const Center(child: Text('Tela de Histórico')),
    );
  }
}