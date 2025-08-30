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
import 'tela_patos.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TelaRecordes extends StatefulWidget {
  const TelaRecordes({super.key});

  @override
  State<TelaRecordes> createState() => _TelaRecordesState();
}

class _TelaRecordesState extends State<TelaRecordes> {
  late Future<EstatisticasRecordes> _recordesFuture;

  @override
  void initState() {
    super.initState();
    _recordesFuture = _calcularRecordes();
  }

  Future<EstatisticasRecordes> _calcularRecordes() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não logado.');

    final snapshot = await FirebaseFirestore.instance
        .collection('campeonatos')
        .where('idCriador', isEqualTo: user.uid)
        .where('status', isEqualTo: 'finalizado')
        .get();

    if (snapshot.docs.isEmpty) return EstatisticasRecordes();

    // Variáveis para guardar os recordes
    RecordeGoleada? maiorGoleada;
    final Map<String, int> contagemTitulos = {};
    final Map<String, EstatisticasJogador> statsGerais = {};

    // Itera por todos os campeonatos para buscar as partidas e classificações
    for (var campDoc in snapshot.docs) {
      final dadosCamp = campDoc.data();
      
      // Contagem de Títulos
      if (dadosCamp.containsKey('campeaoNome')) {
        final campeao = dadosCamp['campeaoNome'] as String;
        if (campeao.isNotEmpty && campeao != 'Final empatada') {
          contagemTitulos[campeao] = (contagemTitulos[campeao] ?? 0) + 1;
        }
      }

      // Agregação de Estatísticas da fase de pontos
      if (dadosCamp.containsKey('classificacao')) {
        for (var dadosJogador in (dadosCamp['classificacao'] as List)) {
          final nome = dadosJogador['nome'] as String;
          statsGerais.putIfAbsent(nome, () => EstatisticasJogador(nome: nome));
          final jogadorStats = statsGerais[nome]!;
          jogadorStats.totalVitorias += (dadosJogador['vitorias'] as num? ?? 0).toInt();
          jogadorStats.totalDerrotas += (dadosJogador['derrotas'] as num? ?? 0).toInt();
          jogadorStats.totalGolsPro += (dadosJogador['golsPro'] as num? ?? 0).toInt();
          jogadorStats.totalGolsContra += (dadosJogador['golsContra'] as num? ?? 0).toInt();
        }
      }

      // Busca de Maior Goleada (requer ler as partidas)
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

      // Busca de Maior Goleada (requer ler as partidas)
      for (var partidaDoc in partidasSnapshot.docs) {
        final dadosPartida = partidaDoc.data();
        if (dadosPartida['finalizada'] == true) {
          final p1 = (dadosPartida['placar1'] as num).toInt();
          final p2 = (dadosPartida['placar2'] as num).toInt();
          final saldo = (p1 - p2).abs();
          final placarVencedorAtual = p1 > p2 ? p1 : p2;

          bool isNewRecord = false;
          if (maiorGoleada == null) {
            isNewRecord = true;
          } else {
            if (saldo > maiorGoleada.saldoDeGols) {
              isNewRecord = true;
            } else if (saldo == maiorGoleada.saldoDeGols) {
              if (placarVencedorAtual > maiorGoleada.placarVencedor) {
                isNewRecord = true;
              }
            }
          }

          if (isNewRecord) {
            maiorGoleada = RecordeGoleada(
              vencedor: p1 > p2 ? dadosPartida['jogador1'] : dadosPartida['jogador2'],
              perdedor: p1 < p2 ? dadosPartida['jogador1'] : dadosPartida['jogador2'],
              placarVencedor: p1 > p2 ? p1 : p2,
              placarPerdedor: p1 < p2 ? p1 : p2,
            );
          }
        }
      }
    }

    // Determina os recordistas a partir dos dados agregados
    final jogadoresStats = statsGerais.values.toList();
    EstatisticasJogador? melhorAtaque = jogadoresStats.isNotEmpty ? jogadoresStats.reduce((a, b) => a.totalGolsPro > b.totalGolsPro ? a : b) : null;
    EstatisticasJogador? melhorDefesa = jogadoresStats.isNotEmpty ? jogadoresStats.reduce((a, b) => a.totalGolsContra < b.totalGolsContra ? a : b) : null;
    EstatisticasJogador? maiorVitorioso = jogadoresStats.isNotEmpty ? jogadoresStats.reduce((a, b) => a.totalVitorias > b.totalVitorias ? a : b) : null;
    
    MapEntry<String, int>? maiorCampeao = contagemTitulos.isNotEmpty ? contagemTitulos.entries.reduce((a, b) => a.value > b.value ? a : b) : null;

    return EstatisticasRecordes(
      maiorGoleada: maiorGoleada,
      melhorAtaque: melhorAtaque,
      melhorDefesa: melhorDefesa,
      maiorCampeao: maiorCampeao,
      maiorVitorioso: maiorVitorioso,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Recordes', style: AppTextStyles.screenTitle),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 130),
              child: FutureBuilder<EstatisticasRecordes>(
                future: _recordesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text('Não foi possível carregar os recordes.'));
                  }

                  final recordes = snapshot.data!;
                  
                  // *** NOVA VERIFICAÇÃO DE CONTEÚDO VAZIO ***
                  if (recordes.maiorGoleada == null &&
                      recordes.melhorAtaque == null &&
                      recordes.maiorCampeao == null &&
                      recordes.maiorVitorioso == null &&
                      recordes.melhorDefesa == null) {
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
                        if (recordes.maiorGoleada != null)
                          RecordCardWidget(
                            titulo: 'Maior goleada',
                            conteudo: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        recordes.maiorGoleada!.vencedor,
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
                                        recordes.maiorGoleada!.perdedor,
                                        textAlign: TextAlign.left,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                  ],
                                ),
                                Text('${recordes.maiorGoleada!.placarVencedor} - ${recordes.maiorGoleada!.placarPerdedor}', style: AppTextStyles.screenTitle.copyWith(fontSize: 32, color: AppColors.textColor)),
                              ],
                            ),
                          ),
                        if (recordes.melhorAtaque != null)
                          RecordCardWidget(
                            titulo: 'Melhor ataque',
                            conteudo: Column(
                              children: [
                                Text(recordes.melhorAtaque!.nome, style: AppTextStyles.screenTitle.copyWith(fontSize: 28)),
                                const SizedBox(height: 2),
                                Text('Total de gols: ${recordes.melhorAtaque!.totalGolsPro}', style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        if (recordes.maiorCampeao != null)
                          RecordCardWidget(
                            titulo: 'Maior campeão',
                            conteudo: Column(
                              children: [
                                Text(recordes.maiorCampeao!.key, style: AppTextStyles.screenTitle.copyWith(fontSize: 28)),
                                const SizedBox(height: 2),
                                Text('Troféus: ${recordes.maiorCampeao!.value}', style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        if (recordes.maiorVitorioso != null)
                          RecordCardWidget(
                            titulo: 'Maior vitorioso',
                            conteudo: Column(
                              children: [
                                Text(recordes.maiorVitorioso!.nome, style: AppTextStyles.screenTitle.copyWith(fontSize: 28)),
                                const SizedBox(height: 2),
                                Text('Partidas vencidas: ${recordes.maiorVitorioso!.totalVitorias}', style: const TextStyle(fontSize: 18)),
                              ],
                            ),
                          ),
                        if (recordes.melhorDefesa != null)
                          RecordCardWidget(
                            titulo: 'Melhor defesa',
                            conteudo: Column(
                              children: [
                                Text(recordes.melhorDefesa!.nome, style: AppTextStyles.screenTitle.copyWith(fontSize: 28)),
                                const SizedBox(height: 2),
                                Text('Gols contra: ${recordes.melhorDefesa!.totalGolsContra}', style: const TextStyle(fontSize: 18)),
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
          Positioned(
            right: 20,
            bottom: 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/pato.svg',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaPatos()));
              },
            ),
          ),
        ],
      ),
    );
  }
}
