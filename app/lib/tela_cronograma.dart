import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/models/campeonato_models.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/widgets/round_card_widget.dart';
import 'tela_inserir_resultado.dart';
import 'package:app/models/modo_campeonato.dart';

class CronogramaData {
  final Map<int, List<Partida>> cronogramaRegular;
  final Partida? partidaFinal;
  final bool finalistasDefinidos;

  CronogramaData({
    required this.cronogramaRegular,
    this.partidaFinal,
    required this.finalistasDefinidos,
  });
}

class TelaCronograma extends StatefulWidget {
  final String campeonatoId;

  const TelaCronograma({super.key, required this.campeonatoId});

  @override
  State<TelaCronograma> createState() => _TelaCronogramaState();
}

// 2. Toda a lógica foi movida para a classe de Estado
class _TelaCronogramaState extends State<TelaCronograma> {
  // 3. Declaramos uma variável de estado para guardar o Future
  late Future<CronogramaData> _cronogramaFuture;

  // 4. Inicializamos o Future no initState
  @override
  void initState() {
    super.initState();
    _cronogramaFuture = _buscarCronograma();
  }
  Future<CronogramaData> _buscarCronograma() async {
    final campeonatoRef = FirebaseFirestore.instance.collection('campeonatos').doc(widget.campeonatoId);

    // Busca o documento do campeonato e a subcoleção de partidas em paralelo para otimizar
    final responses = await Future.wait([
      campeonatoRef.get(),
      campeonatoRef.collection('partidas').orderBy('rodada').get(),
    ]);

    final campeonatoSnapshot = responses[0] as DocumentSnapshot;
    final partidasSnapshot = responses[1] as QuerySnapshot;

    if (!campeonatoSnapshot.exists) {
      throw Exception('Campeonato não encontrado.');
    }

    final dadosCampeonato = campeonatoSnapshot.data() as Map<String, dynamic>;
    final modo = ModoCampeonato.values.firstWhere(
      (e) => e.toString() == dadosCampeonato['modo'],
      orElse: () => ModoCampeonato.pontosCorridosIda,
    );

    // Mapeia todas as partidas do Firestore para o nosso modelo Dart
    final allPartidas = partidasSnapshot.docs.map((doc) {
      final dados = doc.data() as Map<String, dynamic>;
      return Partida(
        id: doc.id,
        rodada: dados['rodada'],
        jogador1: dados['jogador1'],
        jogador2: dados['jogador2'],
        tipo: dados['tipo'] ?? 'regular',
      )
        ..placar1 = dados['placar1']
        ..placar2 = dados['placar2']
        ..placar1Penaltis = dados['placar1Penaltis']
        ..placar2Penaltis = dados['placar2Penaltis']
        ..finalizada = dados['finalizada'];
    }).toList();

    // Separa as partidas da fase de pontos e a partida da final
    final partidasRegulares = allPartidas.where((p) => p.tipo == 'regular').toList();
    Partida? partidaFinal;
    try {
      partidaFinal = allPartidas.firstWhere((p) => p.tipo == 'final');
    } catch (e) {
      partidaFinal = null; // Nenhum jogo final encontrado (acontece em campeonatos antigos)
    }

    // Agrupa as partidas regulares por rodada
    Map<int, List<Partida>> cronogramaRegular = {};
    for (var partida in partidasRegulares) {
      if (!cronogramaRegular.containsKey(partida.rodada)) {
        cronogramaRegular[partida.rodada] = [];
      }
      cronogramaRegular[partida.rodada]!.add(partida);
    }

    bool finalistasDefinidos = false;
    // Lógica para definir os finalistas
    if (modo == ModoCampeonato.pontosCorridosIdaComFinal && partidaFinal != null) {
      final todasRegularesFinalizadas = partidasRegulares.every((p) => p.finalizada);
      if (todasRegularesFinalizadas) {
        finalistasDefinidos = true;
        
        // Pega a classificação já ordenada do documento do campeonato
        final classificacao = (dadosCampeonato['classificacao'] as List);

        if (classificacao.length >= 2) {
          // Atualiza a partida final com os nomes reais dos finalistas
          partidaFinal = Partida(
            id: partidaFinal.id,
            rodada: partidaFinal.rodada,
            jogador1: classificacao[0]['nome'], // 1º colocado
            jogador2: classificacao[1]['nome'], // 2º colocado
            tipo: 'final',
          )
            ..placar1 = partidaFinal.placar1
            ..placar2 = partidaFinal.placar2
            ..placar1Penaltis = partidaFinal.placar1Penaltis
            ..placar2Penaltis = partidaFinal.placar2Penaltis
            ..finalizada = partidaFinal.finalizada;
        }
      }
    }

    return CronogramaData(
      cronogramaRegular: cronogramaRegular,
      partidaFinal: partidaFinal,
      finalistasDefinidos: finalistasDefinidos,
    );
  }
  void _editarPartida(BuildContext context, Partida partida) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TelaInserirResultado(
          campeonatoId: widget.campeonatoId,
          partida: partida,
        ),
      ),
    ).then((_) {
      setState(() {
        _cronogramaFuture = _buscarCronograma();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Cronograma', style: AppTextStyles.screenTitle),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 140),
              child: FutureBuilder<CronogramaData>(
                future: _cronogramaFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text('Nenhum jogo encontrado.'));
                  }

                  final data = snapshot.data!;
                  final cronograma = data.cronogramaRegular;
                  final rodadas = cronograma.keys.toList()..sort();
                  final temFinal = data.partidaFinal != null;

                  return ListView.builder(
                    // O total de itens é o número de rodadas + 1 (para a final, se houver)
                    itemCount: rodadas.length + (temFinal ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Se o índice for menor que o número de rodadas, é uma rodada normal
                      if (index < rodadas.length) {
                        final numeroRodada = rodadas[index];
                        final partidasDaRodada = cronograma[numeroRodada]!;
                        
                        return RoundCardWidget(
                          numeroRodada: numeroRodada,
                          partidas: partidasDaRodada,
                          campeonatoId: widget.campeonatoId,
                          onPartidaEdit: (partida) => _editarPartida(context, partida),
                        );
                      } 
                      // Senão, é o card da Final
                      else {
                        return RoundCardWidget(
                          titulo: 'Final',
                          partidas: [data.partidaFinal!],
                          campeonatoId: widget.campeonatoId,
                          onPartidaEdit: (partida) => _editarPartida(context, partida),
                          // O botão só estará habilitado se os finalistas estiverem definidos
                          isEnabled: data.finalistasDefinidos,
                        );
                      }
                    },
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