import 'package:flutter/material.dart';

class TelaPrincipalCampeonato extends StatelessWidget {
  final String nomeDoCampeonato;
  final List<String> jogadores;

  const TelaPrincipalCampeonato({
    super.key,
    required this.nomeDoCampeonato,
    required this.jogadores,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(nomeDoCampeonato)),
      body: Center(
        child: Text('Campeonato iniciado com ${jogadores.length} jogadores.'),
      ),
    );
  }
}