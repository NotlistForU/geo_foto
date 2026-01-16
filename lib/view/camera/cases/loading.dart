import 'package:flutter/material.dart';

Widget loading({String texto = 'Carregando...'}) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(texto),
        ],
      ),
    ),
  );
}
