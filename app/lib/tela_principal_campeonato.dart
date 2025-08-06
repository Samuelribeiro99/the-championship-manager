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
  // O estado agora é um Future, que será resolvido pelo FutureBuilder
  late Future<void> _dadosCampeonatoFuture;
  List<JogadorNaClassificacao> _classificacao = [];
  List<Partida> _partidas = [];
  Partida? _proximaPartida;

  @override
  void initState() {
    super.initState();
    _dadosCampeonatoFuture = _carregarDadosDoCampeonato();
  }

  // NOVA FUNÇÃO: Busca os dados no Firestore
  Future<void> _carregarDadosDoCampeonato() async {
    // Busca as partidas ordenadas por rodada
    final partidasSnapshot = await FirebaseFirestore.instance
        .collection('campeonatos')
        .doc(widget.campeonatoId)
        .collection('partidas')
        .orderBy('rodada')
        .get();

    final partidasCarregadas = partidasSnapshot.docs.map((doc) {
      final dados = doc.data();
      // TODO: Carregar também placares e status de finalizada
      return Partida(
        rodada: dados['rodada'],
        jogador1: dados['jogador1'],
        jogador2: dados['jogador2'],
      );
    }).toList();

    // TODO: A lógica de cálculo da classificação será feita aqui no futuro
    final classificacaoCarregada = widget.jogadores
        .map((nome) => JogadorNaClassificacao(nome: nome)).toList();

    _partidas = partidasCarregadas;
    _classificacao = classificacaoCarregada;
    _proximaPartida = _encontrarProximaPartida(_partidas);
  }

  Partida? _encontrarProximaPartida(List<Partida> partidas) {
    try {
      return partidas.firstWhere((p) => !p.finalizada);
    } catch (e) {
      return null; // Nenhuma partida encontrada, o campeonato acabou
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
            child: const Text('EXCLUIR'),
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

    if (confirmar == true && mounted) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );

        // Pega a referência do documento do campeonato
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

        if (mounted) Navigator.of(context).pop(); // Esconde o carregamento

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }

      } catch (e) {
        if (mounted) Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir o campeonato: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
  void _mostrarInfoTabela() {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text('Legenda da Tabela'),
      content: const Text('P: Pontos\nJ: Jogos\nV: Vitórias\nE: Empates\nSG: Saldo de Gols\nGP: Gols Pró\nGC: Gols Contra\nÉ possível arrastar a tabela para todos os lados. Experimente!'),
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
          return const BackgroundScaffold(body: Center(child: Text('Erro ao carregar o campeonato.')));
        }

        // O resto do seu build vai aqui, agora que os dados estão carregados
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
                  padding: const EdgeInsets.fromLTRB(16, 80, 16, 120), // Espaço para título e botões
                  child: Column(
                    children: [
                      Text(
                        'Próxima partida',
                        style: AppTextStyles.screenTitle.copyWith(fontSize: 18),
                      ),
                      if (_proximaPartida != null)
                        SelectionButton(
                          svgAsset: 'assets/icons/vai.svg',
                          onPressed: () {
                            // ATUALIZE AQUI
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TelaInserirResultado(
                                  campeonatoId: widget.campeonatoId,
                                  partida: _proximaPartida!,
                                ),
                              ),
                            ).then((_) {
                              // Esta função será chamada quando a tela de resultado for fechada.
                              // Recarregamos os dados para atualizar a tela principal.
                              setState(() {
                                _dadosCampeonatoFuture = _carregarDadosDoCampeonato();
                              });
                            });
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Jogador 1 (à esquerda, flexível)
                              Expanded(
                                child: Text(
                                  _proximaPartida!.jogador1,
                                  textAlign: TextAlign.left,
                                  overflow: TextOverflow.ellipsis, // Adiciona "..." se for muito longo
                                  maxLines: 1,
                                  style: AppTextStyles.screenTitle.copyWith(fontSize: 18), // Reutilizando um estilo
                                ),
                              ),
                              // O "X" no meio
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: SvgPicture.asset(
                                  'assets/icons/x_vs.svg',
                                  height: 30, // <<< Ajuste a altura do "X" como preferir
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.borderYellow, // Ou AppColors.textColor, etc.
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              // Jogador 2 (à direita, flexível)
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
                          text: 'Campeão: ${_classificacao.isNotEmpty ? _classificacao[0].nome : "N/D"}',
                          svgAsset: 'assets/icons/trofeu.svg',
                          onPressed: () { /* Navegar para TelaCampeao */ },
                          alignment: Alignment.center,
                        ),
                      
                      const SizedBox(height: 24),

                      // --- TABELA DE CLASSIFICAÇÃO ---
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.borderYellow, width: 5),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ClipRRect( // Para que o conteúdo não vaze das bordas arredondadas
                            borderRadius: BorderRadius.circular(2.0),
                            // Scroll Horizontal
                            child: SingleChildScrollView(
                              child: SingleChildScrollView( // Este é o que você já tinha (horizontal)
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  border: TableBorder.all(
                                    width: 2.0, // Grossura das linhas internas finas
                                    color: AppColors.borderYellow, // Cor das linhas internas
                                  ),
                                  headingRowColor: WidgetStateProperty.all(
                                    AppColors.borderYellow.withOpacity(0.2), // Cor de destaque para o cabeçalho
                                  ),
                                  dividerThickness: 0,
                                  
                                  horizontalMargin: 4,
                                  columnSpacing: 0,
                                  columns: [
                                    DataColumn(
                                      label: Container(
                                        // Define os limites de largura para a coluna
                                        constraints: const BoxConstraints(
                                          minWidth: 80, // Largura MÍNIMA que a coluna terá
                                          maxWidth: 150, // Largura MÁXIMA que a coluna pode atingir
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('Jogador', style: TextStyle(fontWeight: FontWeight.bold)),
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
                                          // Use EXATAMENTE os mesmos constraints do cabeçalho
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
              
              // --- BOTÕES DE RODAPÉ ---
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
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => TelaCronograma(campeonatoId: widget.campeonatoId),
                        ));
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