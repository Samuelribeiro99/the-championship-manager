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
      'F: Finais Disputadas\n'
      'J: Jogos (fase de pontos + finais)\n'
      'V: Vitórias\n'
      'E: Empates\n'
      'D: Derrotas\n'
      'SG: Saldo de Gols\n'
      'GP: Gols Pró\n'
      'GC: Gols Contra\n'
      'MGP: Média de Gols Pró\n'
      'MGC: Média de Gols Contra\n\n'
      'Critérios de Desempate: APR > V > SG > GP'
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
                    return const Center(child: Text('Nenhuma estatística encontrada.\nFinalize um campeonato para começar.', textAlign: TextAlign.center));
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