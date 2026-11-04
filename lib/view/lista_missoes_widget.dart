import 'package:flutter/material.dart';

class Lista extends StatelessWidget {
  final String nome;
  final bool ativa;
  final VoidCallback onTap;
  final VoidCallback onExportarCsv;
  final VoidCallback? onImportarMapa;
  final VoidCallback? onDeleteMissao;
  const Lista({
    super.key,
    required this.nome,
    required this.ativa,
    required this.onTap,
    required this.onDeleteMissao,
    required this.onExportarCsv,
    this.onImportarMapa,
  });

  @override
  Widget build(BuildContext context) {
    final corTexto = ativa ? Colors.black87 : Colors.white;
    return Card(
      color: ativa ? null : Theme.of(context).colorScheme.primary.withAlpha(20),
      child: ListTile(
        title: Text(
          nome,
          style: TextStyle(
            fontWeight: ativa ? FontWeight.bold : FontWeight.normal,
            color: ativa ? Colors.black87 : Colors.white,
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
            // if (ativa)
            //   Icon(
            //     Icons.check_circle,
            //     color: Theme.of(context).colorScheme.primary,
            //   ),
            IconButton(
              tooltip: 'Exportar CSV',
              icon: Icon(Icons.assignment, color: corTexto),
              onPressed: onExportarCsv,
            ),
            IconButton(
              onPressed: onDeleteMissao,
              icon: Icon(Icons.delete),
              color: ativa ? Colors.black : Colors.white,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
