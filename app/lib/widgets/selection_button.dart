import 'package:app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/square_icon_button.dart';

class SelectionButton extends StatelessWidget {
  final String text;
  final String svgAsset;
  final VoidCallback onPressed;

  const SelectionButton({
    super.key,
    required this.text,
    required this.svgAsset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // O Expanded volta a ser o filho direto da Row
        Expanded(
          // E o SizedBox fica DENTRO do Expanded
          child: SizedBox(
            height: 60, // Forçamos a altura aqui
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom().copyWith(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                alignment: Alignment.centerLeft,
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'PostNoBillsColombo',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        SquareIconButton(
          svgAsset: svgAsset,
          onPressed: onPressed,
          size: 60,
        ),
      ],
    );
  }
}