import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/theme/app_colors.dart';
import 'tela_sala_de_trofeus.dart';

class TelaHallDeCampeoes extends StatefulWidget {
  const TelaHallDeCampeoes({super.key});

  @override
  State<TelaHallDeCampeoes> createState() => _TelaHallDeCampeoesState();
}

class _TelaHallDeCampeoesState extends State<TelaHallDeCampeoes> {
  late Future<Map<String, int>> _titulosPorJogadorFuture;
    final List<Color> _paletaDeCores = const [
    AppColors.borderYellow,
    AppColors.blueishGrey,
    AppColors.yellowCard,
    AppColors.lighterGreen,
    AppColors.woodenBrown,
    Colors.grey, // Cor para a fatia "Outros"
  ];

  @override
  void initState() {
    super.initState();
    _titulosPorJogadorFuture = _contarTitulos();
  }

  /// Busca todos os campeonatos finalizados e conta os títulos de cada jogador.
  Future<Map<String, int>> _contarTitulos() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não logado.');

    final snapshot = await FirebaseFirestore.instance
        .collection('campeonatos')
        .where('idCriador', isEqualTo: user.uid)
        .where('status', isEqualTo: 'finalizado')
        .get();

    if (snapshot.docs.isEmpty) return {};

    final Map<String, int> contagemTitulos = {};
    for (var doc in snapshot.docs) {
      final dados = doc.data();
      // Verificação mais robusta para garantir que o campo existe e não é nulo
      if (dados.containsKey('campeaoNome') && dados['campeaoNome'] != null) {
        final campeao = dados['campeaoNome'] as String;
        // Garante que não contamos campeões com nomes vazios ou placeholders
        if (campeao.isNotEmpty && campeao != 'Final empatada') {
          contagemTitulos[campeao] = (contagemTitulos[campeao] ?? 0) + 1;
        }
      }
    }
    return contagemTitulos;
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Hall de Campeões', style: AppTextStyles.screenTitle),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 100),
              child: FutureBuilder<Map<String, int>>(
                future: _titulosPorJogadorFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar dados: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nenhum campeão definido ainda.\nFinalize um campeonato para começar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      )
                    );
                  }

                  final contagemTitulos = snapshot.data!;
                  final totalTitulos = contagemTitulos.values.fold(0, (soma, item) => soma + item);

                  // Ordena os jogadores por número de títulos
                  final jogadoresOrdenados = contagemTitulos.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value));

                  // --- NOVA LÓGICA DO GRÁFICO DE PIZZA ---
                  List<PieChartSectionData> sections = [];
                  List<MapEntry<String, int>> legenda = [];
                  final bool usarOutros = jogadoresOrdenados.length > 5;

                  if (usarOutros) {
                    // Lógica para mais de 5 campeões (Top 5 + Outros)
                    int outrosTitulos = 0;
                    for (int i = 0; i < jogadoresOrdenados.length; i++) {
                      if (i < 5) {
                        final entry = jogadoresOrdenados[i];
                        legenda.add(entry);
                        sections.add(PieChartSectionData(
                          color: _paletaDeCores[i],
                          value: entry.value.toDouble(),
                          title: '${(entry.value / totalTitulos * 100).toStringAsFixed(0)}%',
                          radius: 100,
                          titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ));
                      } else {
                        outrosTitulos += jogadoresOrdenados[i].value;
                      }
                    }
                    if (outrosTitulos > 0) {
                      legenda.add(MapEntry('Outros', outrosTitulos));
                      sections.add(PieChartSectionData(
                        color: _paletaDeCores.last,
                        value: outrosTitulos.toDouble(),
                        title: '${(outrosTitulos / totalTitulos * 100).toStringAsFixed(0)}%',
                        radius: 100,
                        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ));
                    }
                  } else {
                    // Lógica para 5 ou menos campeões (mostra todos)
                    legenda = jogadoresOrdenados;
                    for (int i = 0; i < jogadoresOrdenados.length; i++) {
                      final entry = jogadoresOrdenados[i];
                      sections.add(PieChartSectionData(
                        color: _paletaDeCores[i],
                        value: entry.value.toDouble(),
                        title: '${(entry.value / totalTitulos * 100).toStringAsFixed(0)}%',
                        radius: 100,
                        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ));
                    }
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // O Gráfico de Pizza
                      SizedBox(
                        height: 250,
                        child: PieChart(PieChartData(sections: sections)),
                      ),
                      const SizedBox(height: 32),
                      // A Legenda
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          for (int i = 0; i < legenda.length; i++)
                            _buildLegendaItem(
                              '${legenda[i].key} (${legenda[i].value})', 
                              _paletaDeCores[i]
                            ),
                        ],
                      ),
                    ],
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
              svgAsset: 'assets/icons/trofeu.svg',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const TelaSalaDeTrofeus()));
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Helper para construir os itens da legenda do gráfico.
  Widget _buildLegendaItem(String nome, Color cor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          color: cor,
        ),
        const SizedBox(width: 8),
        Text(nome),
      ],
    );
  }
}
