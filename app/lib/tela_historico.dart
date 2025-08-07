import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/models/modo_campeonato.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/selection_button.dart';
import 'package:app/theme/text_styles.dart';
import 'tela_principal_campeonato.dart';
import 'package:app/widgets/square_icon_button.dart';

class TelaHistorico extends StatelessWidget {
  const TelaHistorico({super.key});

  // Função que busca os campeonatos no Firestore
  Future<QuerySnapshot> _buscarCampeonatos() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Se não houver usuário, retorna um futuro vazio
      throw Exception('Usuário não está logado.');
    }

    // Busca na coleção 'campeonatos' todos os documentos
    // onde o 'idCriador' é igual ao ID do usuário logado.
    return FirebaseFirestore.instance
        .collection('campeonatos')
        .where('idCriador', isEqualTo: user.uid)
        .orderBy('criadoEm', descending: true) // Mostra os mais recentes primeiro
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Histórico', style: AppTextStyles.screenTitle),
          ),
          
          // --- CONTEÚDO PRINCIPAL COM FUTUREBUILDER ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 140, 24, 140),
              child: FutureBuilder<QuerySnapshot>(
                future: _buscarCampeonatos(),
                builder: (context, snapshot) {
                  // --- ESTADO DE CARREGAMENTO ---
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // --- ESTADO DE ERRO ---
                  if (snapshot.hasError) {
                    return const Center(child: Text('Ocorreu um erro ao buscar os campeonatos.'));
                  }

                  // --- ESTADO SEM DADOS ---
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Nenhum campeonato encontrado.'));
                  }

                  // --- ESTADO DE SUCESSO (COM DADOS) ---
                  final campeonatos = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: campeonatos.length,
                    itemBuilder: (context, index) {
                      // Pega os dados do documento do Firestore
                      final campeonatoDoc = campeonatos[index];
                      final dados = campeonatoDoc.data() as Map<String, dynamic>;
                      
                      final nome = dados['nome'] ?? 'Sem Nome';
                      final status = dados['status'] ?? 'ativo';

                      // Lógica condicional para o ícone
                      final svgAsset = status == 'finalizado'
                          ? 'assets/icons/trofeu.svg'
                          : 'assets/icons/vai.svg';

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: SelectionButton(
                          text: nome,
                          svgAsset: svgAsset,
                          onPressed: () {
                            // Extrai os dados necessários para a próxima tela
                            final jogadoresList = (dados['jogadores'] as List)
                                .map((j) => j['nome'] as String)
                                .toList();
                            
                            // Converte a string do modo de volta para o enum
                            final modo = ModoCampeonato.values.firstWhere(
                              (e) => e.toString() == dados['modo'],
                              orElse: () => ModoCampeonato.pontosCorridosIda,
                            );

                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => TelaPrincipalCampeonato(
                                campeonatoId: campeonatoDoc.id, // Passa o ID
                                nomeDoCampeonato: nome,
                                jogadores: jogadoresList,
                                modo: modo,
                              ),
                            ));
                          },
                        ),
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