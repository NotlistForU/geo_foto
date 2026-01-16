import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

Widget permissaoNegada(BuildContext c) {
  return Scaffold(
    appBar: AppBar(title: const Text('Permissão necessária')),
    body: Center(
      child: ElevatedButton(
        onPressed: openAppSettings,
        child: const Text('Abrir configurações'),
      ),
    ),
  );
}
