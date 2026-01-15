import 'package:flutter/material.dart';

class Lista extends StatelessWidget {
  final String nome;
  final bool ativa;
  final VoidCallback onTap;
  const Lista({
    super.key,
    required this.nome,
    required this.ativa,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ativa ? Theme.of(context).colorScheme.primary.withAlpha(20) : null,
      child: ListTile(
        title: Text(
          nome,
          style: TextStyle(
            fontWeight: ativa ? FontWeight.bold : FontWeight.normal,
            color: ativa ? Colors.white : Colors.black87,
          ),
        ),
        trailing: ativa
            ? Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
