import 'package:flutter/material.dart';
import 'package:sipam_foto/database/missoes/update.dart' as update;
import 'package:sipam_foto/database/missoes/insert.dart' as insert;
import 'package:sipam_foto/database/missoes/select.dart' as select;
import 'package:sipam_foto/model/missao.dart' as model;
import 'package:sipam_foto/view/camera/page.dart' as page;
import 'package:sipam_foto/view/missao/lista.dart';

class Missao extends StatefulWidget {
  const Missao({super.key});

  @override
  State<Missao> createState() => _MissaoState();
}

class _MissaoState extends State<Missao> {
  late Future<List<model.Missao>> missoesFuture;

  @override
  void initState() {
    super.initState();
    _reloadMissoes();
  }

  void _reloadMissoes() {
    missoesFuture = select.Missao.todasMissoes();
  }

  void _openModal() {
    final c = context;
    final textC = TextEditingController();
    bool ativarAgora = true;

    showDialog(
      context: c,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nova missão'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textC,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Nome da missão'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Ativar agora?'),
                  const Spacer(),
                  StatefulBuilder(
                    builder: (_, setLocalState) {
                      return Switch(
                        value: ativarAgora,
                        onChanged: (value) {
                          setLocalState(() {
                            ativarAgora = value;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nome = textC.text.trim();
                if (nome.isEmpty) return;
                final existe = await select.Missao.existeMissao(nome);
                if (!c.mounted) return;
                if (!existe) {
                  ScaffoldMessenger.of(c).showSnackBar(
                    const SnackBar(
                      content: Text('Já existe uma missão com esse nome'),
                    ),
                  );
                  return;
                }
                await insert.Missao.values(nome: nome, ativa: ativarAgora);
                if (!c.mounted) return;
                Navigator.pop(c);
                if (ativarAgora) {
                  Navigator.push(
                    c,
                    MaterialPageRoute(builder: (_) => const page.Camera()),
                  );
                } else {
                  setState(() {
                    _reloadMissoes();
                  });
                }
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context;
    return Scaffold(
      appBar: AppBar(title: const Text('Missões')),
      body: FutureBuilder<List<model.Missao>>(
        future: missoesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          final missoes = snapshot.data ?? [];
          if (missoes.isEmpty) {
            return const Center(child: Text('Nenhuma missão criada'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: missoes.length,
            itemBuilder: (c, index) {
              final missao = missoes[index];
              return Lista(
                nome: missao.nome,
                ativa: missao.ativa,
                onTap: () async {
                  await update.Missao.ativar(missao);
                  if (!c.mounted) return;
                  Navigator.push(
                    c,
                    MaterialPageRoute(builder: (_) => const page.Camera()),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openModal,
        child: const Icon(Icons.add),
      ),
    );
  }
}
