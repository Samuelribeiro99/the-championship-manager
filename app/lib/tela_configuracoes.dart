// Exemplo para historico_screen.dart
import 'package:flutter/material.dart';

class TelaConfiguracoes extends StatelessWidget {
  const TelaConfiguracoes({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: const Center(child: Text('Tela de Configurações')),
    );
  }
}