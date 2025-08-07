import 'package:flutter/material.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/app_colors.dart';

class PlacarJogadorWidget extends StatefulWidget {
  final String nomeJogador;
  final int? placarInicial;

  const PlacarJogadorWidget({
    super.key,
    required this.nomeJogador,
    this.placarInicial,
  });

  @override
  State<PlacarJogadorWidget> createState() => PlacarJogadorWidgetState();
}

class PlacarJogadorWidgetState extends State<PlacarJogadorWidget> {
  int _placar = 0;

  @override
  void initState() {
    super.initState();
    // Se um placar inicial foi fornecido, usa ele. Senão, começa com 0.
    _placar = widget.placarInicial ?? 0;
  }

  int get placarAtual => _placar;

  void _incrementarPlacar() {
    setState(() {
      _placar++;
    });
  }

  void _diminuirPlacar() {
    if (_placar > 0) { // Validação para não permitir placar negativo
      setState(() {
        _placar--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderYellow, width: 5),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          // Nome do Jogador
          Text(
            widget.nomeJogador,
            style: const TextStyle(
              fontFamily: 'PostNoBillsColombo',
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const Expanded(child: SizedBox()), // Espaçador para empurrar o placar para baixo

          // Controles do Placar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Botão de diminuir
              SquareIconButton(
                svgAsset: 'assets/icons/remover.svg',
                onPressed: _diminuirPlacar,
                size: 80,
                hasBorder: false, // Sem borda, como pedido
              ),
              // O placar
              Text(
                '$_placar',
                style: const TextStyle(
                  fontFamily: 'PostNoBillsColombo',
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textColor,
                ),
              ),
              // Botão de aumentar
              SquareIconButton(
                svgAsset: 'assets/icons/adicionar.svg',
                onPressed: _incrementarPlacar,
                size: 80,
                hasBorder: false, // Sem borda, como pedido
              ),
            ],
          ),
        ],
      ),
    );
  }
}