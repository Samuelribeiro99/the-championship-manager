import 'package:flutter/material.dart';

class BackgroundScaffold extends StatelessWidget {
  final Widget body;
  final AppBar? appBar;

  const BackgroundScaffold({
    super.key,
    required this.body,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    // Vamos clonar a AppBar para garantir que ela seja transparente
    final transparentAppBar = appBar != null
        ? AppBar(
            title: appBar!.title,
            leading: appBar!.leading,
            actions: appBar!.actions,
            backgroundColor: Colors.transparent, // Força a transparência
            elevation: 0, // Remove a sombra
          )
        : null;

    return Scaffold(
      // MUDANÇA PRINCIPAL 1: Faz o corpo se estender por trás da AppBar
      extendBodyBehindAppBar: true,
      
      // Usa a nossa AppBar já transparente
      appBar: transparentAppBar,

      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        // O conteúdo da sua tela ficará aqui
        child: body,
      ),
    );
  }
}