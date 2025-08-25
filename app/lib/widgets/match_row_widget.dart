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
  Widget _buildPlayerLine(String nome, int? placar) {
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
          width: 50,
          height: 50, // Altura correspondente
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
            child: Text(
              placar?.toString() ?? '-',
              style: const TextStyle(
                fontFamily: 'PostNoBillsColombo',
                fontSize: 18,
                fontWeight:
                FontWeight.bold
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // A linha inteira da partida
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          // Coluna para empilhar os dois jogadores
          Expanded(
            child: Column(
              children: [
                _buildPlayerLine(partida.jogador1, partida.placar1),
                const SizedBox(height: 14),
                _buildPlayerLine(partida.jogador2, partida.placar2),
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