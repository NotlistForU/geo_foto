import 'package:flutter/material.dart';

Future<bool> confirmarExclusao(
  BuildContext context, {
  String mensagem = 'Deseja realmente excluir esta foto?',
}) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Excluir foto'),
      content: Text(mensagem),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );

  return confirmar ?? false;
}
