import 'package:flutter/material.dart';

Widget erro({required String mensagem}) {
  return Scaffold(
    appBar: AppBar(title: const Text('Erro')),
    body: Center(child: Text(mensagem)),
  );
}
