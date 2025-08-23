import 'package:flutter/material.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ComparisonCardWidget extends StatelessWidget {
  final String titulo;
  final String valorJogador1;
  final String valorJogador2;

  const ComparisonCardWidget({
    super.key,
    required this.titulo,
    required this.valorJogador1,
    required this.valorJogador2,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderYellow, width: 5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: AppTextStyles.screenTitle.copyWith(fontSize: 32),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  valorJogador1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SvgPicture.asset(
                  'assets/icons/x_vs.svg',
                  height: 24,
                  colorFilter: const ColorFilter.mode(AppColors.borderYellow, BlendMode.srcIn),
                ),
              ),
              Expanded(
                child: Text(
                  valorJogador2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
