import 'package:flutter/material.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/menu_button.dart';
import 'package:app/theme/app_colors.dart';

// Importe suas telas placeholder
import 'tela_historico.dart';
// import 'tela_estatisticas.dart';
import 'tela_configuracoes.dart';
import 'tela_sobre.dart';
import 'tela_modo_campeonato.dart';

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
               const SizedBox(height: 30),
              Row(
                children: [
                  // Sua Logo
                  Image.asset(
                    'assets/images/trofeu.png',
                    width: 100,
                    height: 100,
                  ),
                  const SizedBox(width: 16),
                  // Nome do App
                  const Text(
                    'The\nChampionship\nManager',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'PorterSansBlock',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.borderYellow,
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
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaModoCampeonato()));
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
              // MenuButton(
              //   text: 'Estatísticas',
              //   svgAsset: 'assets/icons/estatisticas.svg',
              //   onPressed: () {
              //     Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaEstatisticas()));
              //   },
              // ),
              // const SizedBox(height: 16),
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