import 'package:flutter/material.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/menu_button.dart';
import 'package:app/models/modo_campeonato.dart';
import 'package:app/theme/text_styles.dart';
import 'tela_nome_campeonato.dart';
import 'package:app/widgets/square_icon_button.dart';

class TelaModoCampeonato extends StatelessWidget {
  const TelaModoCampeonato({super.key});

  void _selecionarModo(BuildContext context, ModoCampeonato modo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaNomeCampeonato(modo: modo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Modo de jogo', style: AppTextStyles.screenTitle),
          ),
          Positioned(
            left: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/voltar.svg',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MenuButton(
                    text: 'Pontos Corridos',
                    svgAsset: 'assets/icons/pontos_corridos.svg',
                    iconShape: BoxShape.rectangle,
                    onPressed: () => _selecionarModo(context, ModoCampeonato.pontosCorridosIda),
                  ),
                  const SizedBox(height: 80),
                  MenuButton(
                    text: 'Pontos + Final',
                    svgAsset: 'assets/icons/pontos_final.svg',
                    iconShape: BoxShape.rectangle,
                    onPressed: () => _selecionarModo(context, ModoCampeonato.pontosCorridosIdaComFinal),
                  ),
                  const SizedBox(height: 80),
                  MenuButton(
                    text: 'Torneio',
                    svgAsset: 'assets/icons/torneio.svg',
                    iconShape: BoxShape.rectangle,
                    onPressed: () => _selecionarModo(context, ModoCampeonato.torneio),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}