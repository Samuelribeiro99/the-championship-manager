import 'package:flutter/material.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/theme/app_colors.dart';

class TelaSobre extends StatelessWidget {
  const TelaSobre({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          // Título da Página (continua o mesmo)
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Sobre o App', style: AppTextStyles.screenTitle),
          ),

          // Botão de Voltar (continua o mesmo)
          Positioned(
            left: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/voltar.svg',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // --- CONTEÚDO PRINCIPAL REATORADO ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 140),
              child: Column(
                children: [
                  // 1. Usamos Expanded para dar um limite de altura para o "quadrado"
                  Expanded(
                    // 2. O Container desenha a borda que você pediu
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderYellow, width: 5),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6.0),
                        // 3. O SingleChildScrollView torna o conteúdo interno rolável
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // --- O conteúdo que você já tinha, agora aqui dentro ---
                                Text(
                                  'Nossa missão',
                                  style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Este aplicativo foi criado com o intuito de incentivar a criação de campeonatos e, consequentemente, a interação social. A ideia é usar a tecnologia para tratar um sintoma de seu avanço: o isolamento social. Os "princípios ativos" deste aplicativo são a praticidade e o conjunto de funcionalidades que torna simples e satisfatório a criação e gerenciamento de campeonatos.',
                                  style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                                  textAlign: TextAlign.justify,
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  'A inspiração',
                                  style: AppTextStyles.screenTitle.copyWith(fontSize: 22),
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12.0),
                                  child: Image.asset(
                                    'assets/images/foto_amigos.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 32),
                                const Text(
                                  'A ideia para este app nasceu de momentos marcantes da minha juventude. Em meio a partidas acirradas de FIFA, sentimos a falta de uma ferramenta prática para gerenciar nossos campeonatos. Este aplicativo é uma homenagem a todas as amizades cultivadas e fortalecidas por momentos divididos praticando e competindo um esporte, seja ele real ou virtual.',
                                  style: TextStyle(fontSize: 16, color: Colors.white70, height: 1.5),
                                  textAlign: TextAlign.justify,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}