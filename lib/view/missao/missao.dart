import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:camera_overlay/camera_overlay.dart' as cam;
import 'package:sipam_foto/model/localizacao.dart';
import 'package:sipam_foto/model/missao_model.dart';
import 'package:sipam_foto/view/missao/lista.dart';
import 'package:sipam_foto/view/galeria/page.dart' as page;
import 'package:sipam_foto/view/mapa/mapa_page.dart' as page;
import 'package:sipam_foto/service/arquivo_service.dart';
import 'package:sipam_foto/model/foto_model.dart';
import 'package:sipam_foto/model/missao_model.dart';

class Missao extends StatefulWidget {
  const Missao({super.key});

  @override
  State<Missao> createState() => _MissaoState();
}

class _MissaoState extends State<Missao> {
  final ArquivoService _arquivoService = ArquivoService();
  late Future<List<MissaoModel>> missoesFuture;

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

  void _abrirCamera(int missaoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SafeArea(
          child: cam.CameraOverlay(
            titulo: "Câmera",
            anguloRotacaoDireita: -90,
            anguloRotacaoEsquerda: 90,
            temBotaoGoogleMaps: true,
            temBotaoGaleria: true,
            temMiniMapa: true,
            onFotoFinal: (bytes, localizacao) async {
              // TODO: ajustar onFotoFinal
              // if (localizacao == null) return;
              // final locApp = Localizacao.fromCamera(localizacao);
              // await ArquivoService.salvarFoto(
              //   missaoId: missaoId,
              //   bytes: bytes,
              //   localizacao: locApp,
              // );
            },
            onAbrirGaleria: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const page.Galeria()),
              );
            },
          ),
        ),
      ),
    ).then((_) => setState(() => _reloadMissoes()));
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
                if (ativarAgora) {
                  // TODO: ver fluxo de missao -> mapa -> foto
                  // final missaoAtiva = await MissaoModel.buscarAtiva();
                  // if (missaoAtiva != null) _abrirCamera(missaoAtiva.id);
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
              debugPrint('Botão galeria clicado');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const page.Galeria()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.map),
            tooltip: 'Mapa',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const page.MapaPage()),
              );
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
              final nomeWithId = "${missao.nome} ID: ${missao.id}";
              return Lista(
                nome: nomeWithId,
                ativa: missao.ativa,
                onTap: () async {
                  await MissaoModel.ativarMissao(missao);
                  if (!c.mounted) return;
                  _abrirCamera(missao.id);
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
