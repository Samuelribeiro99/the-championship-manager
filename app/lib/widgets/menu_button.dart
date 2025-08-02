import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/theme/app_colors.dart';

class MenuButton extends StatelessWidget {
  final String text;
  final String svgAsset;
  final VoidCallback onPressed;

  const MenuButton({
    super.key,
    required this.text,
    required this.svgAsset,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Pega as cores do tema para manter a consistência
    final buttonTheme = Theme.of(context).outlinedButtonTheme.style;
    final borderColor = buttonTheme?.side?.resolve({})?.color ?? Colors.white;

    // Usamos um TextButton como base para ter o efeito de clique sem a borda externa
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        // Adiciona um padding para o botão não ficar colado nas bordas
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        // Deixa a área de clique com cantos arredondados, para um toque mais suave
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        children: [
          // ITEM 1: O CÍRCULO COM ÍCONE (AGORA NA ESQUERDA)
          Container(
            width: 90,
            height: 90,
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: 7.0, // Grossura da borda do círculo
              ),
            ),
            child: SvgPicture.asset(
              svgAsset,
              colorFilter: ColorFilter.mode(
                borderColor, // Usa a mesma cor do texto
                BlendMode.srcIn,
              ),
            ),
          ),
          
          const SizedBox(width: 30), // Espaço entre o ícone e o texto

          // ITEM 2: O TEXTO DO BOTÃO (AGORA NA DIREITA)
          Text(
            text,
            style: TextStyle(
              fontFamily: 'PostNoBillsColombo',
              fontSize: 29,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
          ),
        ],
      ),
    );
  }
}