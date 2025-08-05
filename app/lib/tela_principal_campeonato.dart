import 'package:flutter/material.dart';
import 'package:app/models/campeonato_models.dart';
import 'package:app/models/modo_campeonato.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/selection_button.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/theme/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  List<JogadorNaClassificacao> _classificacao = [];
  List<Partida> _partidas = [];
  Partida? _proximaPartida;

  @override
  void initState() {
    super.initState();
    _gerarCampeonato();
  }

  // --- LÓGICA PRINCIPAL ---

  void _gerarCampeonato() {
    // Inicializa a classificação
    final classificacaoInicial = widget.jogadores.map((nome) => JogadorNaClassificacao(nome: nome)).toList();

    // Lógica para gerar jogos de Pontos Corridos (somente ida)
    List<Partida> partidasGeradas = [];
    List<String> jogadoresParaSorteio = List.from(widget.jogadores);

    for (int i = 0; i < jogadoresParaSorteio.length; i++) {
      for (int j = i + 1; j < jogadoresParaSorteio.length; j++) {
        partidasGeradas.add(Partida(
          jogador1: jogadoresParaSorteio[i],
          jogador2: jogadoresParaSorteio[j],
        ));
      }
    }
    partidasGeradas.shuffle(); // Embaralha a ordem dos jogos

    setState(() {
      _classificacao = classificacaoInicial;
      _partidas = partidasGeradas;
      _proximaPartida = _encontrarProximaPartida(partidasGeradas);
    });
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
                      text: '${_proximaPartida!.jogador1}  X  ${_proximaPartida!.jogador2}',
                      svgAsset: 'assets/icons/vai.svg',
                      onPressed: () { /* Navegar para TelaInserirResultado */ },
                      alignment: Alignment.center,
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
                              
                              horizontalMargin: 12,
                              columnSpacing: 0,
                              columns: [
                                const DataColumn(label: SizedBox(width: 60, child: Text('Jogador'))),
                                const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('P')))),
                                const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('J')))),
                                const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('V')))),
                                const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('E')))),
                                const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('SG')))),
                                const DataColumn(label: SizedBox(width: 60, child: Center(child: Text('GP')))),
                                const DataColumn(label: SizedBox(width: 50, child: Center(child: Text('GC')))),
                              ],
                              rows: _classificacao.map((j) => DataRow(
                                cells: [
                                  DataCell(SizedBox(width: 60, child: Text(j.nome, overflow: TextOverflow.ellipsis))),
                                  DataCell(SizedBox(width: 60, child: Center(child: Text(j.pontos.toString())))),
                                  DataCell(SizedBox(width: 60, child: Center(child: Text(j.jogos.toString())))),
                                  DataCell(SizedBox(width: 60, child: Center(child: Text(j.vitorias.toString())))),
                                  DataCell(SizedBox(width: 60, child: Center(child: Text(j.empates.toString())))),
                                  DataCell(SizedBox(width: 60, child: Center(child: Text(j.saldoDeGols.toString())))),
                                  DataCell(SizedBox(width: 60, child: Center(child: Text(j.golsPro.toString())))),
                                  DataCell(SizedBox(width: 50, child: Center(child: Text(j.golsContra.toString())))),
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
                  onPressed: () { /* Navegar para TelaCronograma */ },
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
}