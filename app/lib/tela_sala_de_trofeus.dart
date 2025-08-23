import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/models/estatisticas_models.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'package:app/widgets/trophy_card_widget.dart';
import 'package:app/theme/text_styles.dart';

class TelaSalaDeTrofeus extends StatefulWidget {
  const TelaSalaDeTrofeus({super.key});

  @override
  State<TelaSalaDeTrofeus> createState() => _TelaSalaDeTrofeusState();
}

class _TelaSalaDeTrofeusState extends State<TelaSalaDeTrofeus> {
  late Future<List<CampeonatoFinalizado>> _campeonatosFuture;

  @override
  void initState() {
    super.initState();
    _campeonatosFuture = _buscarCampeonatosFinalizados();
  }

  /// Busca todos os campeonatos com status 'finalizado' do usuário.
  Future<List<CampeonatoFinalizado>> _buscarCampeonatosFinalizados() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não logado.');

    final snapshot = await FirebaseFirestore.instance
        .collection('campeonatos')
        .where('idCriador', isEqualTo: user.uid)
        .where('status', isEqualTo: 'finalizado')
        .orderBy('criadoEm', descending: true)
        .get();

    if (snapshot.docs.isEmpty) return [];

    final List<CampeonatoFinalizado> campeonatos = [];
    for (var doc in snapshot.docs) {
      final dados = doc.data();
      // Adiciona à lista apenas se tiver os dados necessários
      if (dados.containsKey('campeaoNome') && dados.containsKey('trofeuUrl')) {
        campeonatos.add(CampeonatoFinalizado(
          nome: dados['nome'] ?? 'Campeonato sem nome',
          campeaoNome: dados['campeaoNome'],
          trofeuUrl: dados['trofeuUrl'],
        ));
      }
    }
    return campeonatos;
  }

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Stack(
        children: [
          Align(
            alignment: const Alignment(0.0, -0.85),
            child: Text('Sala de Troféus', style: AppTextStyles.screenTitle),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 120, 24, 130),
              child: FutureBuilder<List<CampeonatoFinalizado>>(
                future: _campeonatosFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Erro ao carregar troféus: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('Nenhum campeonato finalizado ainda.'));
                  }

                  final campeonatos = snapshot.data!;

                  // A lista rolável de cards de troféu
                  return ListView.builder(
                    itemCount: campeonatos.length,
                    itemBuilder: (context, index) {
                      return TrophyCardWidget(campeonato: campeonatos[index]);
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
