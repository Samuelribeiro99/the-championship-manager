import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/models/estatisticas_models.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/text_styles.dart';

class TrophyCardWidget extends StatelessWidget {
  final CampeonatoFinalizado campeonato;

  const TrophyCardWidget({super.key, required this.campeonato});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300, // Altura fixa para cada card
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderYellow, width: 5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Nome do Campeonato
          Text(
            campeonato.nome,
            style: AppTextStyles.screenTitle.copyWith(fontSize: 28),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          // Imagem do Troféu
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: campeonato.trofeuUrl.endsWith('.svg')
                  ? SvgPicture.asset(campeonato.trofeuUrl)
                  : Image.asset(campeonato.trofeuUrl),
            ),
          ),
          // Nome do Campeão
          Text(
            'Campeão: ${campeonato.campeaoNome}',
            style: AppTextStyles.screenTitle.copyWith(
              fontSize: 24,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
