// Exemplo para historico_screen.dart
import 'package:flutter/material.dart';

class TelaNovoCampeonato extends StatelessWidget {
  const TelaNovoCampeonato({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Campeonato')),
      body: const Center(child: Text('Tela de Novo Campeonato')),
    );
  }
}