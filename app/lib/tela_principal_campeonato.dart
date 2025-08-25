import 'package:flutter/material.dart';
import 'package:app/models/campeonato_models.dart';
import 'package:app/models/modo_campeonato.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/selection_button.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:app/utils/connectivity_utils.dart';

// Importe suas telas placeholder
import 'tela_inserir_resultado.dart';
import 'tela_campeao.dart';
import 'tela_cronograma.dart';

class TelaPrincipalCampeonato extends StatefulWidget {
  final String campeonatoId;
  final String nomeDoCampeonato;
  final List<String> jogadores;
  final ModoCampeonato modo;

  const TelaPrincipalCampeonato({
    super.key,
    required this.campeonatoId,
    required this.nomeDoCampeonato,
    required this.jogadores,
    required this.modo,
  });

  @override
  State<TelaPrincipalCampeonato> createState() => _TelaPrincipalCampeonatoState();
}

class _TelaPrincipalCampeonatoState extends State<TelaPrincipalCampeonato> {
  late Future<void> _dadosCampeonatoFuture;
  List<JogadorNaClassificacao> _classificacao = [];
  Partida? _proximaPartida;
  String? _trofeuUrl;
  String? _campeaoNome;
  // NOVA VARIÁVEL DE ESTADO
  bool _finalistasDefinidos = false;


  @override
  void initState() {
    super.initState();
    _dadosCampeonatoFuture = _carregarDadosDoCampeonato();
  }

  // FUNÇÃO PRINCIPAL: Busca os dados ATUALIZADOS no Firestore
  Future<void> _carregarDadosDoCampeonato() async {
    final campeonatoRef = FirebaseFirestore.instance.collection('campeonatos').doc(widget.campeonatoId);

    // Busca o documento principal e a subcoleção de partidas ao mesmo tempo
    final responses = await Future.wait([
      campeonatoRef.get(),
      campeonatoRef.collection('partidas').orderBy('rodada').get(),
    ]);

    final campeonatoSnapshot = responses[0] as DocumentSnapshot;
    final partidasSnapshot = responses[1] as QuerySnapshot;
    final dadosCampeonato = campeonatoSnapshot.data() as Map<String, dynamic>;

    // Carrega a classificação JÁ CALCULADA do Firestore
    if (dadosCampeonato.containsKey('classificacao')) {
      _classificacao = (dadosCampeonato['classificacao'] as List).map((dadosJogador) {
        final j = JogadorNaClassificacao(nome: dadosJogador['nome']);
        j.pontos = dadosJogador['pontos'] ?? 0;
        j.jogos = dadosJogador['jogos'] ?? 0;
        j.vitorias = dadosJogador['vitorias'] ?? 0;
        j.empates = dadosJogador['empates'] ?? 0;
        j.derrotas = dadosJogador['derrotas'] ?? 0;
        j.golsPro = dadosJogador['golsPro'] ?? 0;
        j.golsContra = dadosJogador['golsContra'] ?? 0;
        return j;
      }).toList();
    } else { // Fallback para a primeira vez que o campeonato é aberto
      _classificacao = (dadosCampeonato['jogadores'] as List)
          .map((j) => JogadorNaClassificacao(nome: j['nome'])).toList();
    }

    // Carrega as partidas
    final todasAsPartidas = partidasSnapshot.docs.map((doc) {
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
        ..finalizada = dados['finalizada'];
    }).toList();

    _proximaPartida = _encontrarProximaPartida(todasAsPartidas);

    // *** NOVA LÓGICA PARA ATUALIZAR A FINAL ***
    if (widget.modo == ModoCampeonato.pontosCorridosIdaComFinal && _proximaPartida?.tipo == 'final') {
        final partidasRegulares = todasAsPartidas.where((p) => p.tipo == 'regular');
        if (partidasRegulares.every((p) => p.finalizada)) {
            _finalistasDefinidos = true;
            if (_classificacao.length >= 2) {
                _proximaPartida = Partida(
                    id: _proximaPartida!.id,
                    rodada: _proximaPartida!.rodada,
                    jogador1: _classificacao[0].nome,
                    jogador2: _classificacao[1].nome,
                    tipo: 'final',
                )
                ..placar1 = _proximaPartida!.placar1
                ..placar2 = _proximaPartida!.placar2
                ..finalizada = _proximaPartida!.finalizada;
            }
        } else {
            _finalistasDefinidos = false;
        }
    } else {
        _finalistasDefinidos = false;
    }


      if (dadosCampeonato.containsKey('trofeuUrl')) {
        _trofeuUrl = dadosCampeonato['trofeuUrl'];
      }
      if (dadosCampeonato.containsKey('campeaoNome')) {
        _campeaoNome = dadosCampeonato['campeaoNome'];
      }
  }

  // MUDANÇA: A função agora prioriza partidas regulares
  Partida? _encontrarProximaPartida(List<Partida> partidas) {
    try {
      // Tenta encontrar a próxima partida regular não finalizada
      return partidas.firstWhere((p) => p.tipo == 'regular' && !p.finalizada);
    } catch (e) {
      try {
        // Se não houver mais partidas regulares, procura pela final não finalizada
        return partidas.firstWhere((p) => p.tipo == 'final' && !p.finalizada);
      } catch (e) {
        return null; // Nenhuma partida encontrada, o campeonato acabou
      }
    }
  }

  // --- Funções dos Botões ---

  Future<bool?> _mostrarPopupConfirmacao({
    required String titulo,
    required String mensagem,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Retorna false se cancelar
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true), // Retorna true se confirmar
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Future<void> _excluirCampeonato() async {
    final confirmar = await _mostrarPopupConfirmacao(
      titulo: 'Excluir Campeonato',
      mensagem: 'Esta ação é irreversível e todos os dados deste campeonato serão perdidos. Deseja continuar?',
    );

    if (confirmar != true) return;

    // 2. Se confirmou, AGORA chamamos nosso assistente que verifica a internet.
    await executarComVerificacaoDeInternet(
      context,
      acao: () async {
        final campeonatoRef = FirebaseFirestore.instance
            .collection('campeonatos')
            .doc(widget.campeonatoId);

        // 1. Busca todos os documentos na subcoleção 'partidas'
        final partidasSnapshot = await campeonatoRef.collection('partidas').get();

        // 2. Cria um "batch" para deletar todas as partidas em uma única operação
        WriteBatch batch = FirebaseFirestore.instance.batch();
        for (var doc in partidasSnapshot.docs) {
          batch.delete(doc.reference);
        }
        // Executa a exclusão de todas as partidas
        await batch.commit();

        // 3. Depois de deletar as partidas, deleta o documento principal do campeonato
        await campeonatoRef.delete();

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
    );
  }
    
  void _mostrarInfoTabela() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Legenda da Tabela'),
      content: const Text(
        'P: Pontos\n'
        'J: Jogos\n'
        'V: Vitórias\n'
        'E: Empates\n'
        'D: Derrotas\n'
        'SG: Saldo de gols\n'
        'GP: Gols pró\n'
        'GC: Gols contra\n\n'
        'Critério de desempate: P > V > SG > GP > Confronto direto > Sorteio\n\n'
        'Outras informações:\n'
        'O modo de pontos corridos é com partidas somente ida.\n'
        'É possível arrastar a tabela para todos os lados. Experimente!'
        ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _dadosCampeonatoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const BackgroundScaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return BackgroundScaffold(body: Center(child: Text('Erro ao carregar dados: ${snapshot.error}')));
        }
        
        // *** NOVA VARIÁVEL PARA SIMPLIFICAR O BUILD ***
        final bool isFinal = _proximaPartida?.tipo == 'final';

        return BackgroundScaffold(
          body: Stack(
            children: [
              Align(
                alignment: const Alignment(0.0, -0.9),
                child: Text(
                  widget.nomeDoCampeonato,
                  style: AppTextStyles.screenTitle.copyWith(fontSize: 40),
                  textAlign: TextAlign.center,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 100, 16, 130), // Espaço para título e botões
                  child: Column(
                    children: [
                      // *** LÓGICA DO TÍTULO ATUALIZADA ***
                      if (_proximaPartida != null)
                        Text(
                          // Se for a final, mostra "Final", senão "Próxima partida"
                          isFinal ? 'Final' : 'Próxima partida',
                          style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
                        )
                      else
                        Text(
                          'Campeão',
                          style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
                        ),

                      // *** LÓGICA DO BOTÃO ATUALIZADA ***
                      if (_proximaPartida != null)
                        SelectionButton(
                          svgAsset: 'assets/icons/vai.svg',
                          onPressed: () {
                            // A final só é jogável se os finalistas estiverem definidos
                            if (isFinal && !_finalistasDefinidos) return;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TelaInserirResultado(
                                  campeonatoId: widget.campeonatoId,
                                  partida: _proximaPartida!,
                                ),
                              ),
                            ).then((_) {
                              setState(() {
                                _dadosCampeonatoFuture = _carregarDadosDoCampeonato();
                              });
                            });
                          },
                          child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                _proximaPartida!.jogador1,
                                textAlign: TextAlign.left,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: SvgPicture.asset(
                                'assets/icons/x_vs.svg',
                                height: 30,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.borderYellow,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                _proximaPartida!.jogador2,
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                      )
                      else
                        SelectionButton(
                          text: _campeaoNome ?? "N/D",
                          svgAsset: 'assets/icons/trofeu.svg',
                          onPressed: () {
                            if (_campeaoNome != null && _trofeuUrl != null) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => TelaCampeao(
                                  nomeDoCampeonato: widget.nomeDoCampeonato,
                                  nomeDoCampeao: _campeaoNome!,
                                  trofeuUrl: _trofeuUrl!,
                                ),
                              ));
                            }
                          },
                          alignment: Alignment.center,
                        ),
                      
                      const SizedBox(height: 12),

                      // --- TABELA DE CLASSIFICAÇÃO (sem alterações) ---
                      Expanded(
                        child: Container(
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
                                  border: TableBorder.all(
                                    width: 2.0,
                                    color: AppColors.borderYellow,
                                  ),
                                  headingRowColor: WidgetStateProperty.all(
                                    AppColors.borderYellow.withOpacity(0.2),
                                  ),
                                  dividerThickness: 0,
                                  
                                  horizontalMargin: 4,
                                  columnSpacing: 0,
                                  columns: [
                                    DataColumn(
                                      label: Container(
                                        constraints: const BoxConstraints(
                                          minWidth: 80,
                                          maxWidth: 150,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('Participante', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ),
                                    const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('P')))),
                                    const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('J')))),
                                    const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('V')))),
                                    const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('E')))),
                                    const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('D')))),
                                    const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('SG')))),
                                    const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('GP')))),
                                    const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('GC')))),
                                  ],
                                  rows: _classificacao.map((j) => DataRow(
                                    cells: [
                                      DataCell(
                                        Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 80,
                                            maxWidth: 150,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text(j.nome, overflow: TextOverflow.ellipsis),
                                          ),
                                        ),
                                      ),
                                      DataCell(SizedBox(width: 60, child: Center(child: Text(j.pontos.toString())))),
                                      DataCell(SizedBox(width: 60, child: Center(child: Text(j.jogos.toString())))),
                                      DataCell(SizedBox(width: 60, child: Center(child: Text(j.vitorias.toString())))),
                                      DataCell(SizedBox(width: 60, child: Center(child: Text(j.empates.toString())))),
                                      DataCell(SizedBox(width: 60, child: Center(child: Text(j.derrotas.toString())))),
                                      DataCell(SizedBox(width: 60, child: Center(child: Text(j.saldoDeGols.toString())))),
                                      DataCell(SizedBox(width: 60, child: Center(child: Text(j.golsPro.toString())))),
                                      DataCell(SizedBox(width: 60, child: Center(child: Text(j.golsContra.toString())))),
                                    ]
                                  )).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
              
              // --- BOTÕES DE RODAPÉ (sem alterações) ---
              Positioned(
                bottom: 60,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SquareIconButton(
                      svgAsset: 'assets/icons/home.svg',
                      onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    ),
                    SquareIconButton(
                      svgAsset: 'assets/icons/cronograma.svg',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TelaCronograma(campeonatoId: widget.campeonatoId),
                          ),
                        ).then((_) {                          
                          setState(() {
                          _dadosCampeonatoFuture = _carregarDadosDoCampeonato();
                          });
                        });
                      },
                    ),
                    SquareIconButton(
                      svgAsset: 'assets/icons/lixeira.svg',
                      onPressed: _excluirCampeonato,
                    ),
                    SquareIconButton(
                      svgAsset: 'assets/icons/sobre.svg',
                      onPressed: _mostrarInfoTabela,
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
