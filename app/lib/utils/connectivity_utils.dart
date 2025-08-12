// Em lib/utils/connectivity_utils.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/utils/popup_utils.dart';

Future<bool> _verificarConexaoFirebase() async {
  try {
    await FirebaseFirestore.instance
        .collection('connectivityCheck')
        .doc('check')
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 5));
    return true;
  } catch (e) {
    return false;
  }
}

Future<void> executarComVerificacaoDeInternet(
  BuildContext context, {
  required Future<void> Function() acao,
}) async {
  // 1. MOSTRA O CARREGAMENTO IMEDIATAMENTE
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  // 2. VERIFICA A CONEXÃO (o usuário verá o loading durante esta etapa)
  if (!await _verificarConexaoFirebase()) {
    if (context.mounted) {
      // Se falhar, primeiro fecha o loading
      Navigator.of(context).pop();
      // Depois mostra o alerta
      mostrarPopupAlerta(context, 'Não foi possível se conectar ao nosso serviço. Verifique sua conexão com a internet.');
    }
    return;
  }

  // 3. SE CONECTOU, EXECUTA A AÇÃO PRINCIPAL
  try {
    // A 'acao' agora é responsável por fechar o loading no caminho de sucesso
    await acao();

  } catch (e) {
    // 4. SE A 'acao' FALHAR, O CATCH FECHA O LOADING E MOSTRA O ERRO
    if (context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (context.mounted) {
      mostrarPopupAlerta(context, 'Ocorreu um erro: $e');
    }
  }
}