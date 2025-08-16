// Em lib/widgets/selectable_player_button.dart

import 'package:flutter/material.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/app_colors.dart';

class SelectablePlayerButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onPressed;

  const SelectablePlayerButton({
    super.key,
    required this.text,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // O retângulo com o nome
        Expanded(
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom().copyWith(
              backgroundColor: WidgetStateProperty.all(
                isSelected ? AppColors.primaryGreen.withOpacity(0.5) : Colors.transparent,
              ),
              alignment: Alignment.centerLeft,
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
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
        const SizedBox(width: 12),
        // O botão de ícone que muda
        SquareIconButton(
          onPressed: onPressed,
          size: 60,
          svgAsset: isSelected
              ? 'assets/icons/check.svg'
              : 'assets/icons/empty.svg',
        ),
      ],
    );
  }
}