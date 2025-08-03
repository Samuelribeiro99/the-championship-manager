import 'package:flutter/material.dart';

class BackgroundScaffold extends StatelessWidget {
  final Widget body;
  final AppBar? appBar;
  final bool resizeToAvoidBottomInset;

  const BackgroundScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    final transparentAppBar = appBar != null
        ? AppBar(
            title: appBar!.title,
            leading: appBar!.leading,
            actions: appBar!.actions,
            backgroundColor: Colors.transparent,
            elevation: 0,
          )
        : null;

    return Scaffold(
      // 3. USAMOS A PROPRIEDADE RECEBIDA AQUI
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBodyBehindAppBar: true,
      appBar: transparentAppBar,
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: body,
      ),
    );
  }
}