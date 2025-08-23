import 'package:flutter/material.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/theme/text_styles.dart';

class RecordCardWidget extends StatelessWidget {
  final String titulo;
  final Widget conteudo; // Usamos um Widget para ter mais flexibilidade

  const RecordCardWidget({
    super.key,
    required this.titulo,
    required this.conteudo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ocupa toda a largura disponível
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderYellow, width: 5),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          // Título do Card
          Text(
            titulo,
            style: AppTextStyles.screenTitle.copyWith(fontSize: 28),
          ),
          const SizedBox(height: 2),
          // Conteúdo do Card
          conteudo,
        ],
      ),
    );
  }
}
