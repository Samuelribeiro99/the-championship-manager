import 'package:app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:app/widgets/square_icon_button.dart';

class SelectionButton extends StatelessWidget {
  final String? text; // <<< AGORA É OPCIONAL
  final Widget? child; // <<< NOVO PARÂMETRO
  final String svgAsset;
  final VoidCallback onPressed;
  final Alignment alignment;

  const SelectionButton({
    super.key,
    this.text,
    this.child,
    required this.svgAsset,
    required this.onPressed,
    this.alignment = Alignment.centerLeft,
  }) : assert(text != null || child != null, 'É necessário fornecer "text" ou "child".');
  // O 'assert' garante que você não se esqueça de passar um dos dois.

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 60,
            child: OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom().copyWith(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                alignment: alignment,
              ),
              // --- LÓGICA CONDICIONAL AQUI ---
              // Se um 'child' for fornecido, use-o. Senão, use o 'text'.
              child: child ?? Text(
                text!, // O '!' garante que, se child for nulo, text não será.
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