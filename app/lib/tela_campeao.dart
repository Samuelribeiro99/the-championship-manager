import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/text_styles.dart';

class TelaCampeao extends StatelessWidget {
  final String nomeDoCampeonato;
  final String nomeDoCampeao;
  final String trofeuUrl;

  const TelaCampeao({
    super.key,
    required this.nomeDoCampeonato,
    required this.nomeDoCampeao,
    required this.trofeuUrl,
  });

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Título
                  Text(
                    'Campeão',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 50),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    nomeDoCampeonato,
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 50),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),

                  // Imagem do Troféu
                  SizedBox(
                    height: 250,
                    width: 250,
                    // Lógica para mostrar SVG ou PNG
                    child: trofeuUrl.endsWith('.svg')
                      ? SvgPicture.asset(trofeuUrl, fit: BoxFit.cover)
                      : Image.asset(trofeuUrl, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 40),

                  // Nome do Campeão
                  Text(
                    '$nomeDoCampeao!',
                    style: AppTextStyles.screenTitle.copyWith(fontSize: 50),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/voltar.svg',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }
}