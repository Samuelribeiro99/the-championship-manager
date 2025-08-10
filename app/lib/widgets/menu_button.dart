import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/theme/app_colors.dart';

class MenuButton extends StatelessWidget {
  final String text;
  final String svgAsset;
  final VoidCallback onPressed;
  final BoxShape iconShape;

  const MenuButton({
    super.key,
    required this.text,
    required this.svgAsset,
    required this.onPressed,
    this.iconShape = BoxShape.circle,
  });

  @override
  Widget build(BuildContext context) {
    final buttonTheme = Theme.of(context).outlinedButtonTheme.style;
    final borderColor = buttonTheme?.side?.resolve({})?.color ?? Colors.white;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              // USA A NOVA PROPRIEDADE PARA DEFINIR A FORMA
              shape: iconShape,
              // Adiciona bordas arredondadas se for um retângulo
              borderRadius: iconShape == BoxShape.rectangle
                  ? BorderRadius.circular(12)
                  : null,
              border: Border.all(
                color: borderColor,
                width: 7.0,
              ),
            ),
            child: SvgPicture.asset(
              svgAsset,
              colorFilter: ColorFilter.mode(
                borderColor,
                BlendMode.srcIn,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PostNoBillsColombo',
                fontSize: 29,
                fontWeight: FontWeight.bold,
                color: AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}