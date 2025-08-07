import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/models/campeonato_models.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/widgets/round_card_widget.dart';
import 'tela_inserir_resultado.dart';

class TelaCronograma extends StatefulWidget {
  final String campeonatoId;

  const TelaCronograma({super.key, required this.campeonatoId});

  @override
  State<TelaCronograma> createState() => _TelaCronogramaState();
}

// 2. Toda a lógica foi movida para a classe de Estado
class _TelaCronogramaState extends State<TelaCronograma> {
  // 3. Declaramos uma variável de estado para guardar o Future
  late Future<Map<int, List<Partida>>> _cronogramaFuture;

  // 4. Inicializamos o Future no initState
  @override
  void initState() {
    super.initState();
    _cronogramaFuture = _buscarCronograma();
  }
  Future<Map<int, List<Partida>>> _buscarCronograma() async {
    final partidasSnapshot = await FirebaseFirestore.instance
        .collection('campeonatos')
        .doc(widget.campeonatoId)
        .collection('partidas')
        .orderBy('rodada')
        .get();

    final partidas = partidasSnapshot.docs.map((doc) {
      final dados = doc.data();
      return Partida(
        id: doc.id,
        rodada: dados['rodada'],
        jogador1: dados['jogador1'],
        jogador2: dados['jogador2'],
      )
        ..placar1 = dados['placar1']
        ..placar2 = dados['placar2']
        ..finalizada = dados['finalizada'];
    }).toList();
    
    Map<int, List<Partida>> cronograma = {};
    for (var partida in partidas) {
      if (!cronograma.containsKey(partida.rodada)) {
        cronograma[partida.rodada] = [];
      }
      cronograma[partida.rodada]!.add(partida);
    }
    return cronograma;
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
              child: FutureBuilder<Map<int, List<Partida>>>(
                future: _cronogramaFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum jogo encontrado.'));
                  }

                  final cronograma = snapshot.data!;
                  final rodadas = cronograma.keys.toList()..sort();

                  return ListView.builder(
                    itemCount: rodadas.length,
                    itemBuilder: (context, index) {
                      final numeroRodada = rodadas[index];
                      final partidasDaRodada = cronograma[numeroRodada]!;
                      
                      return RoundCardWidget(
                        numeroRodada: numeroRodada,
                        partidas: partidasDaRodada,
                        campeonatoId: widget.campeonatoId,
                        onPartidaEdit: (partida) => _editarPartida(context, partida),
                      );
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