import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SquareIconButton extends StatelessWidget {
  final String svgAsset;
  final VoidCallback onPressed;
  final double size; // Opcional: para permitir tamanhos diferentes se precisar

  const SquareIconButton({
    super.key,
    required this.svgAsset,
    required this.onPressed,
    this.size = 50.0, // Tamanho padrão de 50x50
  });

  @override
  Widget build(BuildContext context) {
    // Pega o estilo do tema para usar a cor do ícone
    final buttonStyle = Theme.of(context).outlinedButtonTheme.style;
    final iconColor = buttonStyle?.foregroundColor?.resolve({});

    return OutlinedButton(
      onPressed: onPressed,
      
      // Herda o tema e sobrescreve apenas o tamanho e o padding
      style: OutlinedButton.styleFrom().copyWith(
        minimumSize: WidgetStateProperty.all(Size(size, size)),
        maximumSize: WidgetStateProperty.all(Size(size, size)),
        padding: WidgetStateProperty.all(const EdgeInsets.all(10)), // Espaço para o ícone
        // A borda e outras características vêm do tema!
      ),
      
      child: SvgPicture.asset(
        svgAsset,
        // Faz o ícone SVG usar a cor definida no tema do botão
        colorFilter: ColorFilter.mode(
          iconColor ?? Colors.white, // Usa a cor do tema ou branco como fallback
          BlendMode.srcIn,
        ),
      ),
    );
  }
}