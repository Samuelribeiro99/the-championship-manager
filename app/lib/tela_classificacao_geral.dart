import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/models/estatisticas_models.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/theme/app_colors.dart';
import 'package:app/utils/popup_utils.dart';

class TelaClassificacaoGeral extends StatefulWidget {
  const TelaClassificacaoGeral({super.key});

  @override
  State<TelaClassificacaoGeral> createState() => _TelaClassificacaoGeralState();
}

class _TelaClassificacaoGeralState extends State<TelaClassificacaoGeral> {
  late Future<List<EstatisticasJogador>> _estatisticasFuture;

  @override
  void initState() {
    super.initState();
    _estatisticasFuture = _calcularEstatisticasGerais();
  }

  /// Busca todos os campeonatos finalizados e agrega os dados dos jogadores.
  Future<List<EstatisticasJogador>> _calcularEstatisticasGerais() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não logado.');

    final snapshot = await FirebaseFirestore.instance
        .collection('campeonatos')
        .where('idCriador', isEqualTo: user.uid)
        .where('status', isEqualTo: 'finalizado')
        .get();

    if (snapshot.docs.isEmpty) return [];

    final Map<String, EstatisticasJogador> statsMap = {};

    for (var doc in snapshot.docs) {
      final dados = doc.data();
      if (dados.containsKey('classificacao')) {
        final classificacao = dados['classificacao'] as List;
        for (var dadosJogador in classificacao) {
          final nome = dadosJogador['nome'] as String;
          
          // Se o jogador ainda não está no nosso mapa, adiciona ele
          statsMap.putIfAbsent(nome, () => EstatisticasJogador(nome: nome));

          // Agrega (soma) as estatísticas
          final jogadorStats = statsMap[nome]!;
          jogadorStats.totalPontos += (dadosJogador['pontos'] as num? ?? 0).toInt();
          jogadorStats.totalJogos += (dadosJogador['jogos'] as num? ?? 0).toInt();
          jogadorStats.totalVitorias += (dadosJogador['vitorias'] as num? ?? 0).toInt();
          jogadorStats.totalEmpates += (dadosJogador['empates'] as num? ?? 0).toInt();
          jogadorStats.totalDerrotas += (dadosJogador['derrotas'] as num? ?? 0).toInt();
          jogadorStats.totalGolsPro += (dadosJogador['golsPro'] as num? ?? 0).toInt();
          jogadorStats.totalGolsContra += (dadosJogador['golsContra'] as num? ?? 0).toInt();
        }
      }

      // *** NOVA LÓGICA PARA CONTAR FINAIS ***
      final partidasSnapshot = await doc.reference.collection('partidas').where('tipo', isEqualTo: 'final').get();
      for (var partidaDoc in partidasSnapshot.docs) {
        final dadosPartida = partidaDoc.data();
        if (dadosPartida['finalizada'] == true) {
            final j1 = dadosPartida['jogador1'] as String;
            final j2 = dadosPartida['jogador2'] as String;
            final p1 = (dadosPartida['placar1'] as num).toInt();
            final p2 = (dadosPartida['placar2'] as num).toInt();

            final statsJ1 = statsMap[j1];
            final statsJ2 = statsMap[j2];

            if (statsJ1 != null && statsJ2 != null) {
                statsJ1.totalFinais++;
                statsJ2.totalFinais++;

                statsJ1.totalGolsPro += p1;
                statsJ1.totalGolsContra += p2;
                statsJ2.totalGolsPro += p2;
                statsJ2.totalGolsContra += p1;

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
                    statsJ1.totalPontos += 3; // Adiciona 3 pontos para a vitória na final (para o cálculo do APR)
                    statsJ2.totalDerrotas++;
                } else {
                    statsJ2.totalVitorias++;
                    statsJ2.totalPontos += 3; // Adiciona 3 pontos para a vitória na final (para o cálculo do APR)
                    statsJ1.totalDerrotas++;
                }
            }
        }
      }
    }

    final listaFinal = statsMap.values.toList();

    // Ordena a lista com base nos critérios de desempate
    listaFinal.sort((a, b) {
      int compAproveitamento = b.aproveitamento.compareTo(a.aproveitamento);
      if (compAproveitamento != 0) return compAproveitamento;
      int compVitorias = b.totalVitorias.compareTo(a.totalVitorias);
      if (compVitorias != 0) return compVitorias;
      int compSG = b.saldoDeGols.compareTo(a.saldoDeGols);
      if (compSG != 0) return compSG;
      return b.totalGolsPro.compareTo(a.totalGolsPro);
    });

    return listaFinal;
  }

  void _mostrarInfo() {
    mostrarPopupAlerta(context, 
      'A classificação geral agrega os dados de todos os campeonatos finalizados.\n\n'
      'APR: Aproveitamento (%)\n'
      'F: Finais disputadas\n'
      'J: Jogos (fase de pontos + finais)\n'
      'V: Vitórias\n'
      'E: Empates\n'
      'D: Derrotas\n'
      'F: Finais Disputadas\n'
      'SG: Saldo de gols\n'
      'GP: Gols pró\n'
      'GC: Gols contra\n'
      'MGP: Média de cols pró\n'
      'MGC: Média de gols contra\n\n'
      'Critérios de desempate: APR > V > SG > GP'
    );
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Classificação geral', style: AppTextStyles.screenTitle),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 130),
              child: FutureBuilder<List<EstatisticasJogador>>(
                future: _estatisticasFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar estatísticas: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhuma estatística encontrada.\nFinalize um campeonato para começar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      )
                    );
                  }

                  final estatisticas = snapshot.data!;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.borderYellow, width: 5),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2.0),
                      child: SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            border: TableBorder.all(width: 2.0, color: AppColors.borderYellow),
                            headingRowColor: MaterialStateProperty.all(AppColors.borderYellow.withOpacity(0.2)),
                            dividerThickness: 0,
                            horizontalMargin: 4,
                            columnSpacing: 0,
                            columns: const [
                              DataColumn(label: SizedBox(width: 150, child: Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('Participante', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 70, child: Center(child: Text('APR (%)', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 60, child: Center(child: Text('F', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 60, child: Center(child: Text('J', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 60, child: Center(child: Text('V', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 60, child: Center(child: Text('E', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 60, child: Center(child: Text('D', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 60, child: Center(child: Text('SG', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 60, child: Center(child: Text('GP', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 60, child: Center(child: Text('GC', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 70, child: Center(child: Text('MGP', style: TextStyle(fontWeight: FontWeight.bold))))),
                              DataColumn(label: SizedBox(width: 70, child: Center(child: Text('MGC', style: TextStyle(fontWeight: FontWeight.bold))))),
                            ],
                            rows: estatisticas.map((stats) => DataRow(
                              cells: [
                                DataCell(SizedBox(width: 150, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(stats.nome, overflow: TextOverflow.ellipsis)))),
                                DataCell(SizedBox(width: 70, child: Center(child: Text(stats.aproveitamento.toStringAsFixed(1))))),
                                DataCell(SizedBox(width: 60, child: Center(child: Text(stats.totalFinais.toString())))),
                                DataCell(SizedBox(width: 60, child: Center(child: Text((stats.totalJogos + stats.totalFinais).toString())))),
                                DataCell(SizedBox(width: 60, child: Center(child: Text(stats.totalVitorias.toString())))),
                                DataCell(SizedBox(width: 60, child: Center(child: Text(stats.totalEmpates.toString())))),
                                DataCell(SizedBox(width: 60, child: Center(child: Text(stats.totalDerrotas.toString())))),
                                DataCell(SizedBox(width: 60, child: Center(child: Text(stats.saldoDeGols.toString())))),
                                DataCell(SizedBox(width: 60, child: Center(child: Text(stats.totalGolsPro.toString())))),
                                DataCell(SizedBox(width: 60, child: Center(child: Text(stats.totalGolsContra.toString())))),
                                DataCell(SizedBox(width: 70, child: Center(child: Text(stats.mediaGolsPro.toStringAsFixed(2))))),
                                DataCell(SizedBox(width: 70, child: Center(child: Text(stats.mediaGolsContra.toStringAsFixed(2))))),
                              ]
                            )).toList(),
                          ),
                        ),
                      ),
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
              svgAsset: 'assets/icons/sobre.svg',
              onPressed: _mostrarInfo,
            ),
          ),
        ],
      ),
    );
  }
}