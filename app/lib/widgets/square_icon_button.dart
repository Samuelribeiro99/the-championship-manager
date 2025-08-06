import 'package:app/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SquareIconButton extends StatelessWidget {
  final String svgAsset;
  final VoidCallback onPressed;
  final double size;
  final bool hasBorder;

  const SquareIconButton({
    super.key,
    required this.svgAsset,
    required this.onPressed,
    this.size = 60.0,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = AppColors.borderYellow;

    return OutlinedButton(
      onPressed: onPressed,
      
      // Herda o tema e sobrescreve apenas o tamanho e o padding
      style: OutlinedButton.styleFrom().copyWith(
        minimumSize: WidgetStateProperty.all(Size(size, size)),
        maximumSize: WidgetStateProperty.all(Size(size, size)),
        padding: WidgetStateProperty.all(const EdgeInsets.all(10)),
        side: !hasBorder ? MaterialStateProperty.all(BorderSide.none) : null,
      ),
      
      child: SvgPicture.asset(
        svgAsset,
        colorFilter: ColorFilter.mode(
          iconColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}