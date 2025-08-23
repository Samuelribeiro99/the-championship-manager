import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/models/estatisticas_models.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/widgets/selection_button.dart';
import 'package:app/widgets/comparison_card_widget.dart';
import 'package:app/theme/text_styles.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/theme/app_colors.dart';
import 'tela_selecao_confronto.dart';
import 'package:app/widgets/record_card_widget.dart';


class TelaConfrontoDireto extends StatefulWidget {
  final String jogador1;
  final String jogador2;

  const TelaConfrontoDireto({
    super.key,
    required this.jogador1,
    required this.jogador2,
  });

  @override
  State<TelaConfrontoDireto> createState() => _TelaConfrontoDiretoState();
}

class _TelaConfrontoDiretoState extends State<TelaConfrontoDireto> {
  late Future<ConfrontoDiretoStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _calcularConfrontoDireto();
  }

  Future<ConfrontoDiretoStats> _calcularConfrontoDireto() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não logado.');

    final stats = ConfrontoDiretoStats(jogador1: widget.jogador1, jogador2: widget.jogador2);

    final snapshot = await FirebaseFirestore.instance
        .collection('campeonatos')
        .where('idCriador', isEqualTo: user.uid)
        .get();

    for (var campDoc in snapshot.docs) {
      final partidasSnapshot = await campDoc.reference.collection('partidas').get();
      for (var partidaDoc in partidasSnapshot.docs) {
        final dados = partidaDoc.data();
        final j1 = dados['jogador1'];
        final j2 = dados['jogador2'];
        
        // Verifica se a partida é entre os dois jogadores selecionados
        if ((j1 == widget.jogador1 && j2 == widget.jogador2) || (j1 == widget.jogador2 && j2 == widget.jogador1)) {
          if (dados['finalizada'] == true) {
            final p1 = (dados['placar1'] as num).toInt();
            final p2 = (dados['placar2'] as num).toInt();

            if (p1 == p2) {
              stats.empates++;
            } else if ((j1 == widget.jogador1 && p1 > p2) || (j2 == widget.jogador1 && p2 > p1)) {
              stats.vitoriasJogador1++;
            } else {
              stats.vitoriasJogador2++;
            }
            
            if (j1 == widget.jogador1) {
              stats.golsJogador1 += p1;
              stats.golsJogador2 += p2;
            } else {
              stats.golsJogador1 += p2;
              stats.golsJogador2 += p1;
            }
          }
        }
      }
    }
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Confronto direto', style: AppTextStyles.screenTitle, textAlign: TextAlign.center),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 130),
              child: Column(
                children: [
                  // Botão de Seleção de Jogadores
                  SelectionButton(
                    svgAsset: 'assets/icons/editar.svg',
                    onPressed: () {
                      // Permite trocar os jogadores
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TelaSelecaoConfronto()));
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: Text(widget.jogador1, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: AppTextStyles.screenTitle.copyWith(fontSize: 26))),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: SvgPicture.asset('assets/icons/x_vs.svg', height: 22, colorFilter: const ColorFilter.mode(AppColors.borderYellow, BlendMode.srcIn))),
                        Expanded(child: Text(widget.jogador2, textAlign: TextAlign.left, overflow: TextOverflow.ellipsis, style: AppTextStyles.screenTitle.copyWith(fontSize: 26))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Conteúdo com as estatísticas
                  Expanded(
                    child: FutureBuilder<ConfrontoDiretoStats>(
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return const Center(child: Text('Não foi possível carregar os dados.'));
                        }

                        final stats = snapshot.data!;
                        
                        return SingleChildScrollView(
                          child: Column(
                            children: [
                              RecordCardWidget(
                                titulo: 'Total de partidas',
                                conteudo: Text(stats.totalPartidas.toString(), style: AppTextStyles.screenTitle.copyWith(fontSize: 32)),
                              ),
                              ComparisonCardWidget(
                                titulo: 'Vitórias',
                                valorJogador1: stats.vitoriasJogador1.toString(),
                                valorJogador2: stats.vitoriasJogador2.toString(),
                              ),
                              RecordCardWidget(
                                titulo: 'Empates',
                                conteudo: Text(stats.empates.toString(), style: AppTextStyles.screenTitle.copyWith(fontSize: 32)),
                              ),
                              ComparisonCardWidget(
                                titulo: 'Gols marcados',
                                valorJogador1: stats.golsJogador1.toString(),
                                valorJogador2: stats.golsJogador2.toString(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
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
