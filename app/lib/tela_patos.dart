import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/models/estatisticas_models.dart';
import 'package:app/models/modo_campeonato.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/widgets/record_card_widget.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/theme/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TelaPatos extends StatefulWidget {
  const TelaPatos({super.key});

  @override
  State<TelaPatos> createState() => _TelaPatosState();
}

class _TelaPatosState extends State<TelaPatos> {
  late Future<EstatisticasPatos> _patosFuture;

  @override
  void initState() {
    super.initState();
    _patosFuture = _calcularPatos();
  }

  Future<EstatisticasPatos> _calcularPatos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não logado.');

    final snapshot = await FirebaseFirestore.instance
        .collection('campeonatos')
        .where('idCriador', isEqualTo: user.uid)
        .where('status', isEqualTo: 'finalizado')
        .get();

    if (snapshot.docs.isEmpty) return EstatisticasPatos();

    // Variáveis para guardar os recordes negativos
    RecordeGoleada? piorGoleadaSofrida;
    final Map<String, int> contagemLanternas = {};
    final Map<String, EstatisticasJogador> statsGerais = {};

    for (var campDoc in snapshot.docs) {
      final dadosCamp = campDoc.data();
      
      if (dadosCamp.containsKey('classificacao')) {
        final classificacao = dadosCamp['classificacao'] as List;
        if (classificacao.isNotEmpty) {
          // Contagem de Lanternas
          final lanternaNome = classificacao.last['nome'] as String;
          contagemLanternas[lanternaNome] = (contagemLanternas[lanternaNome] ?? 0) + 1;
        }

        // Agregação de Estatísticas da fase de pontos
        for (var dadosJogador in classificacao) {
          final nome = dadosJogador['nome'] as String;
          statsGerais.putIfAbsent(nome, () => EstatisticasJogador(nome: nome));
          final jogadorStats = statsGerais[nome]!;
          jogadorStats.totalDerrotas += (dadosJogador['derrotas'] as num? ?? 0).toInt();
          jogadorStats.totalVitorias += (dadosJogador['vitorias'] as num? ?? 0).toInt();
          jogadorStats.totalGolsPro += (dadosJogador['golsPro'] as num? ?? 0).toInt();
          jogadorStats.totalGolsContra += (dadosJogador['golsContra'] as num? ?? 0).toInt();
        }
      }

      // Busca de Pior Goleada
      final partidasSnapshot = await campDoc.reference.collection('partidas').get();

      // CORREÇÃO: Adiciona os stats da final, se houver
      final modo = ModoCampeonato.values.firstWhere(
        (e) => e.toString() == dadosCamp['modo'],
        orElse: () => ModoCampeonato.pontosCorridosIda,
      );
      
      if (modo == ModoCampeonato.pontosCorridosIdaComFinal) {
        try {
          final finalDoc = partidasSnapshot.docs.firstWhere((doc) => doc.data()['tipo'] == 'final');
          final dadosPartida = finalDoc.data();

          if (dadosPartida['finalizada'] == true) {
              final j1 = dadosPartida['jogador1'] as String;
              final j2 = dadosPartida['jogador2'] as String;
              final p1 = (dadosPartida['placar1'] as num).toInt();
              final p2 = (dadosPartida['placar2'] as num).toInt();

              final statsJ1 = statsGerais[j1];
              final statsJ2 = statsGerais[j2];

              if (statsJ1 != null && statsJ2 != null) {
                  // Adiciona os gols da final
                  statsJ1.totalGolsPro += p1;
                  statsJ1.totalGolsContra += p2;
                  statsJ2.totalGolsPro += p2;
                  statsJ2.totalGolsContra += p1;

                  // Determina o vencedor da final e adiciona vitória/derrota
                  String vencedor;
                  if (p1 > p2) {
                      vencedor = j1;
                  } else if (p2 > p1) {
                      vencedor = j2;
                  } else {
                      final pen1 = (dadosPartida['placar1Penaltis'] as num?)?.toInt() ?? 0;
                      final pen2 = (dadosPartida['placar2Penaltis'] as num?)?.toInt() ?? 0;
                      vencedor = pen1 > pen2 ? j1 : j2;
                  }

                  if (vencedor == j1) {
                      statsJ1.totalVitorias++;
                      statsJ2.totalDerrotas++;
                  } else {
                      statsJ2.totalVitorias++;
                      statsJ1.totalDerrotas++;
                  }
              }
          }
        } catch (e) {
            // Nenhuma final encontrada neste campeonato, ignora.
        }
      }

      // Busca de Pior Goleada
      for (var partidaDoc in partidasSnapshot.docs) {
        final dadosPartida = partidaDoc.data();
        if (dadosPartida['finalizada'] == true && dadosPartida['placar1'] != null && dadosPartida['placar2'] != null) {
          final p1 = (dadosPartida['placar1'] as num).toInt();
          final p2 = (dadosPartida['placar2'] as num).toInt();
          final saldo = (p1 - p2).abs();
          final placarVencedorAtual = p1 > p2 ? p1 : p2;

          bool isNewRecord = false;
          if (piorGoleadaSofrida == null) {
            isNewRecord = true;
          } else {
            if (saldo > piorGoleadaSofrida.saldoDeGols) {
              isNewRecord = true;
            } else if (saldo == piorGoleadaSofrida.saldoDeGols) {
              if (placarVencedorAtual > piorGoleadaSofrida.placarVencedor) {
                isNewRecord = true;
              }
            }
          }

          if (isNewRecord) {
            piorGoleadaSofrida = RecordeGoleada(
              vencedor: p1 > p2 ? dadosPartida['jogador1'] : dadosPartida['jogador2'],
              perdedor: p1 < p2 ? dadosPartida['jogador1'] : dadosPartida['jogador2'],
              placarVencedor: p1 > p2 ? p1 : p2,
              placarPerdedor: p1 < p2 ? p1 : p2,
            );
          }
        }
      }
    }

    // Determina os "recordistas" a partir dos dados agregados
    final jogadoresStats = statsGerais.values.toList();
    EstatisticasJogador? piorAtaque = jogadoresStats.isNotEmpty ? jogadoresStats.reduce((a, b) => a.totalGolsPro < b.totalGolsPro ? a : b) : null;
    EstatisticasJogador? piorDefesa = jogadoresStats.isNotEmpty ? jogadoresStats.reduce((a, b) => a.totalGolsContra > b.totalGolsContra ? a : b) : null;
    EstatisticasJogador? maiorPerdedor = jogadoresStats.isNotEmpty ? jogadoresStats.reduce((a, b) => a.totalDerrotas > b.totalDerrotas ? a : b) : null;
    
    MapEntry<String, int>? maiorLanterna = contagemLanternas.isNotEmpty ? contagemLanternas.entries.reduce((a, b) => a.value > b.value ? a : b) : null;

    return EstatisticasPatos(
      piorGoleadaSofrida: piorGoleadaSofrida,
      piorAtaque: piorAtaque,
      piorDefesa: piorDefesa,
      maiorPerdedor: maiorPerdedor,
      maiorLanterna: maiorLanterna,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Mural da vergonha', style: AppTextStyles.screenTitle),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 130),
              child: FutureBuilder<EstatisticasPatos>(
                future: _patosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text('Não foi possível carregar os dados.'));
                  }

                  final patos = snapshot.data!;

                  // *** NOVA VERIFICAÇÃO DE CONTEÚDO VAZIO ***
                  if (patos.piorGoleadaSofrida == null &&
                      patos.maiorLanterna == null &&
                      patos.piorAtaque == null &&
                      patos.maiorPerdedor == null &&
                      patos.piorDefesa == null) {
                    return const Center(
                      child: Text(
                        'Nenhum campeonato finalizado. \nFinalize um campeonato para começar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        if (patos.piorGoleadaSofrida != null)
                          RecordCardWidget(
                            titulo: 'Maior goleada sofrida',
                            conteudo: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        patos.piorGoleadaSofrida!.vencedor,
                                        textAlign: TextAlign.right,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                      child: SvgPicture.asset(
                                        'assets/icons/x_vs.svg',
                                        height: 26,
                                        colorFilter: const ColorFilter.mode(AppColors.borderYellow, BlendMode.srcIn),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        patos.piorGoleadaSofrida!.perdedor,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${patos.piorGoleadaSofrida!.placarVencedor} - ${patos.piorGoleadaSofrida!.placarPerdedor}',
                                  style: AppTextStyles.screenTitle.copyWith(fontSize: 32, color: AppColors.textColor)
                                  ),
                              ],
                            ),
                          ),
                        if (patos.maiorLanterna != null)
                          RecordCardWidget(
                            titulo: 'Maior lanterna',
                            conteudo: Column(
                              children: [
                                Text(patos.maiorLanterna!.key, style: AppTextStyles.screenTitle.copyWith(fontSize: 28)),
                                const SizedBox(height: 2),
                                Text(
                                  'Último lugar: ${patos.maiorLanterna!.value} ${patos.maiorLanterna!.value == 1 ? 'vez' : 'vezes'}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        if (patos.piorAtaque != null)
                          RecordCardWidget(
                            titulo: 'Pior ataque',
                            conteudo: Column(
                              children: [
                                Text(patos.piorAtaque!.nome, style: AppTextStyles.screenTitle.copyWith(fontSize: 28)),
                                const SizedBox(height: 2),
                                Text('Total de gols: ${patos.piorAtaque!.totalGolsPro}', style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        if (patos.maiorPerdedor != null)
                          RecordCardWidget(
                            titulo: 'Maior perdedor',
                            conteudo: Column(
                              children: [
                                Text(patos.maiorPerdedor!.nome, style: AppTextStyles.screenTitle.copyWith(fontSize: 28)),
                                const SizedBox(height: 2),
                                Text('Total de derrotas: ${patos.maiorPerdedor!.totalDerrotas}', style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        if (patos.piorDefesa != null)
                          RecordCardWidget(
                            titulo: 'Pior defesa',
                            conteudo: Column(
                              children: [
                                Text(patos.piorDefesa!.nome, style: AppTextStyles.screenTitle.copyWith(fontSize: 28)),
                                const SizedBox(height: 2),
                                Text('Gols contra: ${patos.piorDefesa!.totalGolsContra}', style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  );
                },
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
