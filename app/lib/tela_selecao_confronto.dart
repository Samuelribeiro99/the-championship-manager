import 'package:flutter/material.dart';

class TelaSelecaoConfronto extends StatelessWidget {
  const TelaSelecaoConfronto({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Confronto')),
      body: const Center(child: Text('Tela de Seleção de Confronto Direto')),
    );
  }
}