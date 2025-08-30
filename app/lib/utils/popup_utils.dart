// Em lib/utils/popup_utils.dart

import 'package:flutter/material.dart';

/// Exibe um pop-up de alerta padrão (AlertDialog) com um título, uma mensagem e botões de ação.
///
/// [context] é o BuildContext da tela que está chamando o pop-up.
/// [mensagem] é o texto que será exibido no corpo do alerta.
/// [titulo] é o título opcional do pop-up.
/// [acoesExtras] é uma lista opcional de widgets (botões) a serem adicionados antes do "Ok" padrão.
Future<void> mostrarPopupAlerta(
  BuildContext context,
  String mensagem, {
  String titulo = 'Atenção',
  List<Widget>? acoesExtras,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      // Constrói a lista de ações
      List<Widget> actions = [];

      // Adiciona as ações extras primeiro, se existirem
      if (acoesExtras != null) {
        actions.addAll(acoesExtras);
      }

      // Adiciona o botão "Ok" padrão por último
      actions.add(
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(); // Fecha o pop-up
          },
        ),
      );

      return AlertDialog(
        title: Text(titulo),
        content: Text(mensagem),
        actions: actions,
      );
    },
  );
}

Future<bool?> mostrarPopupConfirmacao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String textoConfirmar = 'Confirmar',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(titulo),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Retorna false
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true), // Retorna true
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red, // Deixa o botão de confirmação vermelho para ações perigosas
          ),
          child: Text(textoConfirmar),
        ),
      ],
    ),
  );
}