import 'package:flutter/material.dart';
import 'package:app/models/campeonato_models.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/app_colors.dart';

class MatchRowWidget extends StatelessWidget {
  final Partida partida;
  final VoidCallback onPressed;
  final bool isEnabled;

  const MatchRowWidget({
    super.key,
    required this.partida,
    required this.onPressed,
    this.isEnabled = true,
  });

  // Helper para construir a linha de um jogador (Nome + Placar)
  Widget _buildPlayerLine(String nome, int? placar, int? placarPenaltis) {
    return Row(
      children: [
        // Retângulo com o nome do jogador
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderYellow, width: 5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Text(
              nome,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'PostNoBillsColombo',
                fontSize: 18,
                fontWeight:
                FontWeight.bold
              ),
            ),
          ),
        ),
        // Quadrado com o placar
        Container(
          width: 70, // Aumenta a largura para caber os pênaltis
          height: 50, 
          decoration: const BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(color: AppColors.borderYellow, width: 5),
            ),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Row( // Usa uma Row para mostrar ambos os placares
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  placar?.toString() ?? '-',
                  style: const TextStyle(
                    fontFamily: 'PostNoBillsColombo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (placarPenaltis != null)
                  Text(
                    " (${placarPenaltis})",
                    style: const TextStyle(
                      fontFamily: 'PostNoBillsColombo',
                      fontSize: 14, // Fonte menor para pênaltis
                      fontWeight: FontWeight.bold,
                      // color: AppColors.textColor, // Cor diferente
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Condição para mostrar os pênaltis
    final bool mostrarPenaltis = partida.tipo == 'final' &&
        partida.finalizada &&
        partida.placar1 == partida.placar2 &&
        partida.placar1Penaltis != null &&
        partida.placar2Penaltis != null;

    // A linha inteira da partida
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          // Coluna para empilhar os dois jogadores
          Expanded(
            child: Column(
              children: [
                _buildPlayerLine(partida.jogador1, partida.placar1, mostrarPenaltis ? partida.placar1Penaltis : null),
                const SizedBox(height: 14),
                _buildPlayerLine(partida.jogador2, partida.placar2, mostrarPenaltis ? partida.placar2Penaltis : null),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Botão de editar
          SquareIconButton(
            svgAsset: partida.finalizada 
              ? 'assets/icons/editar.svg' 
              : 'assets/icons/vai.svg',
            onPressed: isEnabled ? onPressed : null,
            size: 50,
          ),
        ],
      ),
    );
  }
}