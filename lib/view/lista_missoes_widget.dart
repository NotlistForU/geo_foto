import 'package:flutter/material.dart';

class Lista extends StatelessWidget {
  final String nome;
  final bool ativa;
  final VoidCallback onTap;
  final VoidCallback? onImportarMapa;
  const Lista({
    super.key,
    required this.nome,
    required this.ativa,
    required this.onTap,
    this.onImportarMapa,
  });

  @override
  Widget build(BuildContext context) {
    final corTexto = ativa ? Colors.white : Colors.black87;
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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onImportarMapa != null)
              IconButton(
                tooltip: 'Importar mapa',
                icon: Icon(Icons.upload, color: corTexto),
                onPressed: onImportarMapa,
              ),
            if (ativa)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
