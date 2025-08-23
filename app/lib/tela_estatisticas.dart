import 'package:flutter/material.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/selection_button.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/text_styles.dart';

// Importa as telas placeholder que acabamos de criar
import 'tela_classificacao_geral.dart';
import 'tela_hall_de_campeoes.dart';
import 'tela_recordes.dart';
import 'tela_selecao_confronto.dart';

class TelaEstatisticas extends StatelessWidget {
  const TelaEstatisticas({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          // Título da Página
          const Align(
            alignment: Alignment(0.0, -0.85),
            child: Text(
              'Estatísticas',
              style: AppTextStyles.screenTitle,
            ),
          ),

          // Conteúdo Principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 150), // Espaço para o título não sobrepor
                  // --- LISTA DE BOTÕES DE SELEÇÃO ---
                  SelectionButton(
                    text: 'Classificação geral',
                    svgAsset: 'assets/icons/classificacao_geral.svg',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaClassificacaoGeral()));
                    },
                  ),
                  const SizedBox(height: 16),
                  SelectionButton(
                    text: 'Hall de Campeões',
                    svgAsset: 'assets/icons/novo_campeonato.svg',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaHallDeCampeoes()));
                    },
                  ),
                  const SizedBox(height: 16),
                  SelectionButton(
                    text: 'Recordes',
                    svgAsset: 'assets/icons/recordes.svg',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaRecordes()));
                    },
                  ),
                  const SizedBox(height: 16),
                  SelectionButton(
                    text: 'Confronto direto',
                    svgAsset: 'assets/icons/confronto_direto.svg',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaSelecaoConfronto()));
                    },
                  ),

                  const Spacer(), // O Spacer empurra o conteúdo acima para o topo
                ],
              ),
            ),
          ),

          // --- BOTÃO DE VOLTAR NO CANTO INFERIOR ESQUERDO ---
          Positioned(
            left: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/voltar.svg',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}