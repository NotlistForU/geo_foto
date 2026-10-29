import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sipam_foto/model/foto_model.dart';
import 'package:sipam_foto/model/mapa_model.dart';
import 'package:sipam_foto/model/missao_model.dart';
import 'package:sipam_foto/model/ponto_model.dart';
import 'package:sipam_foto/service/importar_mapa_service.dart';
import 'package:sipam_foto/view/lista_missoes_widget.dart';
import 'package:sipam_foto/view/galeria_page.dart' as page;
import 'package:sipam_foto/view/mapa_page.dart' as page;
import 'package:sipam_foto/service/arquivo_service.dart';
import 'package:sipam_foto/service/csv_service.dart';

class MissaoPage extends StatefulWidget {
  const MissaoPage({super.key});

  @override
  State<MissaoPage> createState() => _MissaoPageState();
}

class _MissaoPageState extends State<MissaoPage> {
  final ArquivoService _arquivoService = ArquivoService();
  late Future<List<MissaoModel>> missoesFuture;
  bool _importando = false;

  @override
  void initState() {
    super.initState();
    _reloadMissoes();
  }

  void _reloadMissoes() {
    setState(() {
      missoesFuture = MissaoModel.listar();
    });
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
                final missaoExiste = await MissaoModel.buscarPorNome(nome);
                if (!c.mounted) return;
                if (missaoExiste != null) {
                  ScaffoldMessenger.of(c).showSnackBar(
                    const SnackBar(
                      content: Text('Já existe uma missão com esse nome'),
                    ),
                  );
                  return;
                }
                final missao = MissaoModel(
                  id: 0,
                  data: DateTime.now(),
                  nome: nome,
                  ativa: false, // ativa depois no ativarMissao(missao);
                );
                final missaoId = await MissaoModel.inserir(missao);
                if (ativarAgora) {
                  MissaoModel.ativarMissaoPorId(missaoId);
                }
                if (!c.mounted) return;
                Navigator.pop(c);

                final criada = MissaoModel(
                  id: missaoId,
                  data: missao.data,
                  nome: missao.nome,
                  ativa: ativarAgora,
                );

                if (ativarAgora) {
                  _importarMapa(criada);
                }
                _reloadMissoes();
              },
              child: const Text('Criar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importarMapa(MissaoModel missao) async {
    if (_importando) return;
    _importando = true;

    try {
      ZipMapa? zip;

      try {
        zip = await MapaImporter.ler();
      } on FormatException catch (e) {
        _aviso('Mapa inválido: ${e.message}');
        return;
      } catch (e) {
        _aviso('Erro ao importar mapa: $e');
        return;
      }

      if (zip == null) return; // cancelou

      String? pngPath;

      try {
        // 1. Perguntas, sem gravar nada
        final resumo = await MapaImporter.resumo(missao.id);
        if (resumo.pontosManuais > 0 || resumo.fotos > 0) {
          final ok = await _confirmarSobrescrever(resumo);
          if (!ok || !mounted) return;
        }

        var camadas = <String>[];
        if (zip.camadas.isNotEmpty) {
          final escolhidas = await _escolherCamadas(zip.camadas);
          if (escolhidas == null || !mounted) return;
          camadas = escolhidas;
        }

        // 2. Gravação
        final antigo = await MapaModel.buscarPorMissao(missao.id);
        pngPath = await MapaImporter.salvarPng(zip);

        await MapaImporter.gravar(
          missaoId: missao.id,
          zip: zip,
          pngPath: pngPath,
          camadas: camadas,
        );

        // Banco já gravado: falha de limpeza não desfaz a importação
        try {
          await ArquivoService.excluirPastaPontos(missao);
          if (antigo != null) {
            final arquivoAntigo = File(antigo.imagePath);
            if (await arquivoAntigo.exists()) await arquivoAntigo.delete();
          }
        } catch (e, st) {
          _aviso('Erro ao limpar arquivos antigos: $e\n$st');
        }

        _aviso('Mapa importado em "${missao.nome}"');
      } catch (e, st) {
        _aviso('Erro ao salvar mapa: $e\n$st');

        if (pngPath != null) {
          final arquivo = File(pngPath);
          if (await arquivo.exists()) await arquivo.delete();
        }
        _aviso('Erro ao salvar mapa: $e');
      }
    } finally {
      _importando = false;
    }
  }

  Future<bool> _confirmarSobrescrever(ResumoMissao r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sobrescrever missão?'),
        content: Text(
          'Esta missão tem ${r.pontosManuais} ponto(s) manuais criado(s) em campo '
          'e ${r.fotos} foto(s). Importar um novo mapa vai APAGAR todos eles. Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Apagar e importar'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// null = cancelou; lista vazia = só o mapa.
  Future<List<String>?> _escolherCamadas(
    Map<String, List<PontoImportado>> camadas,
  ) {
    final marcadas = camadas.keys.toSet();

    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Camadas com pontos'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final e in camadas.entries)
                  CheckboxListTile(
                    value: marcadas.contains(e.key),
                    title: Text(e.key),
                    subtitle: Text('${e.value.length} ponto(s)'),
                    onChanged: (v) => setS(() {
                      v == true ? marcadas.add(e.key) : marcadas.remove(e.key);
                    }),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, marcadas.toList()),
              child: Text(marcadas.isEmpty ? 'Só o mapa' : 'Importar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _excluirMissao(MissaoModel missao) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir missão?'),
        content: Text(
          '"${missao.nome}" será apagada junto com o mapa, os pontos e as '
          'fotos. Isso não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      final result = await ArquivoService.excluirMissao(missao);
      if (!mounted) return;
      final msg = switch (result) {
        ResultadoExclusao.completa => 'Missão excluída',
        ResultadoExclusao.arquivosPendentes =>
          'Missão excluída, mas alguns arquivos não puderam ser removidos',
      };
      _aviso(msg);
    } catch (e) {
      _aviso('Erro ao excluir missão: $e');
    }

    _reloadMissoes();
  }

  Future<FormatoCsv?> _escolherFormatoCsv() async {
    return showDialog<FormatoCsv>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Formato do CSV'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Brasil'),
              subtitle: const Text('Separador ; e decimal ,'),
              onTap: () {
                Navigator.pop(context, FormatoCsv.brasil);
              },
            ),
            ListTile(
              title: const Text('Internacional'),
              subtitle: const Text('Separador , e decimal .'),
              onTap: () {
                Navigator.pop(context, FormatoCsv.internacional);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _compartilharMissaoCsv(MissaoModel missao) async {
    final fotos = await FotoModel.listarPorMissao(missao.id);

    if (!mounted) return;

    if (fotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Essa missão não tem fotos')),
      );
      return;
    }

    final formato = await _escolherFormatoCsv();

    if (!mounted || formato == null) return;

    try {
      final listaPontos = await PontoModel.listarPorMissao(
        missao.id,
      ); // ajusta pro nome real
      final pontos = {for (final p in listaPontos) p.id: p};

      await CsvService.compartilharMissaoCsv(
        missao: missao,
        fotos: fotos,
        pontos: pontos,
        formato: formato,
      );
    } catch (e) {
      if (!mounted) return;
      _aviso('Erro ao gerar o CSV');
    }
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  bool _isCheckingMission = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Missões'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Galeria',
            onPressed: () {
              _reloadMissoes();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const page.GaleriaPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Mapa',
            onPressed: () async {
              // Se já estiver checando o banco, ignora cliques repetidos
              if (_isCheckingMission) return;

              setState(() {
                _isCheckingMission = true;
              });

              try {
                final missaoAtiva = await MissaoModel.getMissaoAtiva();

                if (!context.mounted) return;

                if (missaoAtiva == null) {
                  // Limpa qualquer SnackBar antigo da tela imediatamente antes de mostrar o novo
                  ScaffoldMessenger.of(context).clearSnackBars();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Nenhuma missão ativa, mapa não aberto."),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(
                        seconds: 2,
                      ), // Define um tempo curto de exibição
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const page.MapaPage()),
                );
              } finally {
                // Garante que o botão volte a funcionar após o término da operação
                if (context.mounted) {
                  setState(() {
                    _isCheckingMission = false;
                  });
                }
                _reloadMissoes();
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<MissaoModel>>(
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
              final nomeWithId = " ID: ${missao.id} ${missao.nome}";
              return Lista(
                nome: nomeWithId,
                ativa: missao.ativa,
                onTap: () async {
                  await MissaoModel.ativarMissao(missao);
                  if (!c.mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const page.MapaPage()),
                  );
                  _reloadMissoes();
                },
                onExportarCsv: () => _compartilharMissaoCsv(missao),
                onImportarMapa: () => _importarMapa(missao),
                onDeleteMissao: () => _excluirMissao(missao),
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
