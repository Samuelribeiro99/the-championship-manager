import 'package:flutter/material.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/menu_button.dart';
import 'package:app/models/modo_campeonato.dart';
import 'package:app/theme/text_styles.dart';
import 'tela_nome_campeonato.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/utils/popup_utils.dart';

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

  // NOVA FUNÇÃO para mostrar o pop-up de informações
  void _mostrarInfoModos(BuildContext context) {
    const String mensagem = 'Pontos corridos:\n'
        'Todos os participantes se enfrentam em turno único. O campeão é aquele que somar mais pontos ao final de todas as partidas.\n\n'
        'Pontos corridos + final:\n'
        'Funciona como o modo de pontos corridos, mas com a adição de uma partida final entre os dois primeiros colocados para definir o grande campeão.';

    mostrarPopupAlerta(context, mensagem, titulo: 'Modos de Jogo');
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
          // NOVO BOTÃO "SOBRE"
          Positioned(
            right: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/sobre.svg',
              onPressed: () => _mostrarInfoModos(context),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 100),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MenuButton(
                    text: 'Pontos corridos',
                    svgAsset: 'assets/icons/pontos_corridos.svg',
                    iconShape: BoxShape.rectangle,
                    onPressed: () => _selecionarModo(context, ModoCampeonato.pontosCorridosIda),
                  ),
                  const SizedBox(height: 80),
                  MenuButton(
                    text: 'Pontos corridos\n+ final',
                    svgAsset: 'assets/icons/pontos_final.svg',
                    iconShape: BoxShape.rectangle,
                    onPressed: () => _selecionarModo(context, ModoCampeonato.pontosCorridosIdaComFinal),
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
