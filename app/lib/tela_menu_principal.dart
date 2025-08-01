import 'package:flutter/material.dart';
import 'package:app/widgets/background_scaffold.dart'; // Ajuste o caminho
import 'package:app/widgets/menu_button.dart'; // Ajuste o caminho

// Importe suas telas placeholder
import 'tela_novo_campeonato.dart';
import 'tela_historico.dart';
import 'tela_estatisticas.dart';
import 'tela_configuracoes.dart';
import 'tela_sobre.dart';

class TelaMenuPrincipal extends StatelessWidget {
  const TelaMenuPrincipal({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // --- CABEÇALHO COM LOGO E NOME ---
              Row(
                children: [
                  // Sua Logo
                  Image.asset(
                    'assets/images/trofeu.png', // <<< COLOQUE O NOME DA SUA LOGO AQUI
                    width: 60,
                    height: 60,
                  ),
                  const SizedBox(width: 16),
                  // Nome do App
                  const Text(
                    'Championship\nManager',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),

              const Spacer(), // O Spacer empurra os botões para o centro/baixo

              // --- LISTA DE BOTÕES ---
              MenuButton(
                text: 'Novo Campeonato',
                svgAsset: 'assets/icons/novo_campeonato.svg', // <<< USE SEUS ÍCONES
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaNovoCampeonato()));
                },
              ),
              const SizedBox(height: 16),
              MenuButton(
                text: 'Histórico',
                svgAsset: 'assets/icons/historico.svg',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaHistorico()));
                },
              ),
              const SizedBox(height: 16),
              MenuButton(
                text: 'Estatísticas',
                svgAsset: 'assets/icons/estatisticas.svg',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaEstatisticas()));
                },
              ),
              const SizedBox(height: 16),
              MenuButton(
                text: 'Configurações',
                svgAsset: 'assets/icons/configuracoes.svg',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaConfiguracoes()));
                },
              ),
              const SizedBox(height: 16),
              MenuButton(
                text: 'Sobre',
                svgAsset: 'assets/icons/sobre.svg',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaSobre()));
                },
              ),
              
              const Spacer(), // O Spacer empurra os botões para o centro/baixo
            ],
          ),
        ),
      ),
    );
  }
}