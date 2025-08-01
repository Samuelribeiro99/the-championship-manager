// Exemplo para historico_screen.dart
import 'package:flutter/material.dart';

class TelaEstatisticas extends StatelessWidget {
  const TelaEstatisticas({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Estatísticas')),
      body: const Center(child: Text('Tela de Estatísticas')),
    );
  }
}