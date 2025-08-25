import 'package:flutter/material.dart';
import 'package:app/models/campeonato_models.dart';
import 'package:app/widgets/match_row_widget.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/text_styles.dart';

class RoundCardWidget extends StatelessWidget {
  final int? numeroRodada;
  final String? titulo;
  final List<Partida> partidas;
  final String campeonatoId;
  final Function(Partida) onPartidaEdit;
  final bool isEnabled;

  const RoundCardWidget({
    super.key,
    this.numeroRodada,
    this.titulo,
    required this.partidas,
    required this.campeonatoId,
    required this.onPartidaEdit,
    this.isEnabled = true,
  }) : assert(numeroRodada != null || titulo != null, 'É necessário fornecer "numeroRodada" ou "titulo".');

  @override
  Widget build(BuildContext context) {
    // O "quadrado da rodada" com a borda
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderYellow, width: 5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título da rodada
          Text(
            titulo ?? 'Rodada $numeroRodada',
            style: AppTextStyles.screenTitle.copyWith(fontSize: 30),
          ),
          // Lista de partidas, usando o widget que acabamos de criar
          ...partidas.map((partida) => MatchRowWidget(
            partida: partida,
            onPressed: () => onPartidaEdit(partida),
            isEnabled: isEnabled,
          )).toList(),
        ],
      ),
    );
  }
}