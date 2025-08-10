import 'package:flutter/material.dart';
import 'package:app/widgets/background_scaffold.dart';
import 'package:app/widgets/square_icon_button.dart';
import 'tela_adicionar_jogadores.dart';
import 'package:app/theme/text_styles.dart';
import 'package:app/models/modo_campeonato.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelaNomeCampeonato extends StatefulWidget {
  final ModoCampeonato modo;
  const TelaNomeCampeonato({super.key, required this.modo});

  @override
  State<TelaNomeCampeonato> createState() => _TelaNomeCampeonatoState();
}

class _TelaNomeCampeonatoState extends State<TelaNomeCampeonato> {
  final _nomeController = TextEditingController();

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _avancarParaAdicionarJogadores() async {
    FocusScope.of(context).unfocus();
    final nomeCampeonato = _nomeController.text.trim();

    if (nomeCampeonato.isEmpty) {
      // Usando um pop-up em vez de SnackBar para consistência
      _mostrarPopupAlerta('Por favor, dê um nome ao campeonato.');
      return;
    }

    // Mostra um indicador de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuário não logado");

      // Consulta o Firestore para ver se o nome já existe
      final querySnapshot = await FirebaseFirestore.instance
          .collection('campeonatos')
          .where('idCriador', isEqualTo: user.uid)
          .where('nome_lowercase', isEqualTo: nomeCampeonato.toLowerCase())
          .limit(1) // Otimização: só precisamos saber se existe 1, não precisa buscar todos
          .get();

      // Esconde o indicador de carregamento
      if (mounted) Navigator.of(context).pop();

      // Se a lista de documentos não for vazia, significa que o nome já existe
      if (querySnapshot.docs.isNotEmpty) {
        _mostrarPopupAlerta('Já existe um campeonato com este nome.');
      } else {
        // Se não existe, avança para a próxima tela
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TelaAdicionarJogadores(
              // Lembre-se que esta tela precisa receber o 'modo'
              modo: widget.modo, // Certifique-se que sua tela recebe o modo
              nomeDoCampeonato: nomeCampeonato,
            ),
          ),
        );
      }
    } catch (e) {
      // Esconde o indicador de carregamento em caso de erro
      if (mounted) Navigator.of(context).pop();
      _mostrarPopupAlerta('Ocorreu um erro ao verificar o nome: $e');
    }
  }

  // Adicione esta função auxiliar para o pop-up, se ela não existir
  Future<void> _mostrarPopupAlerta(String mensagem) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atenção'),
        content: Text(mensagem),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return BackgroundScaffold(
      body: Stack(
        children: [
          const Align(
            alignment: Alignment(0.0, -0.7),
            child: Text(
              'Nome do campeonato',
              style: AppTextStyles.screenTitle,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    textCapitalization: TextCapitalization.sentences,
                    controller: _nomeController,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      labelText: 'Digite o nome aqui',
                      counterText: "",
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                  ),
                ],
              ),
            ),
          ),
          
          // --- BOTÕES DE NAVEGAÇÃO ---
          Positioned(
            left: 20,
            bottom: isKeyboardVisible ? 20 : 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/voltar.svg',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            right: 20,
            bottom: isKeyboardVisible ? 20 : 60,
            child: SquareIconButton(
              svgAsset: 'assets/icons/check.svg',
              onPressed: _avancarParaAdicionarJogadores,
            ),
          ),
        ],
      ),
    );
  }
}