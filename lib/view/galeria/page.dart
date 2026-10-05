import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sipam_foto/view/galeria/foto.dart' as galeria_foto;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sipam_foto/model/foto_model.dart';
import 'package:sipam_foto/model/filtro.dart' as model;
import 'package:sipam_foto/view/galeria/modal.dart' as modal;
import 'package:sipam_foto/service/arquivo_service.dart';
import 'package:sipam_foto/view/galeria/thumbnail.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sipam_foto/view/galeria/utils.dart';

class Galeria extends StatefulWidget {
  const Galeria({super.key});
  @override
  State<Galeria> createState() => _GaleriaState();
}

enum TipoOrdem { maisRecente, maisAntigas, crescente, decrescente }

class _GaleriaState extends State<Galeria> {
  final service.ArquivoService _arquivoService = service.ArquivoService();
  TipoOrdem _ordemAtual = TipoOrdem.maisRecente;
  bool loading = true;
  List<FotoModel> fotos = [];
  List<FotoModel> fotosSelecionadas = [];
  Map<int, File> arquivos = {};
  model.Filtro filtroAtual = model.Filtro.empty;

  @override
  void initState() {
    super.initState();
    carregarGaleria();

    PhotoManager.addChangeCallback(_onPhotoLibraryChanged);
    PhotoManager.startChangeNotify();
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_onPhotoLibraryChanged);
    PhotoManager.stopChangeNotify();
    super.dispose();
  }

  void _onPhotoLibraryChanged(MethodCall call) {
    // Apenas se a tela tiver aberta -> tenta recarregar.
    if (mounted) {
      carregarGaleria();
    }
  }

  void _ordenarLista(TipoOrdem novaOrdem) {
    setState(() {
      _ordemAtual = novaOrdem;

      switch (_ordemAtual) {
        case TipoOrdem.maisRecente:
          fotos.sort((a, b) => b.data.compareTo(a.data));
          break;
        case TipoOrdem.maisAntigas:
          fotos.sort((a, b) => a.data.compareTo(b.data));
          break;
        case TipoOrdem.crescente:
          fotos.sort((a, b) => a.numero.compareTo(b.numero));
          break;
        case TipoOrdem.decrescente:
          fotos.sort((a, b) => b.numero.compareTo(a.numero));
          break;
      }
    });
  }

  Future<void> carregarGaleria() async {
    setState(() => loading = true);

    final resultado = await _arquivoService.(filtroAtual);

    final List<FotoModel> listFotos = [];
    final Map<int, File> mapArquivos = {};

    for (final registro in resultado) {
      listFotos.add(registro.foto);
      mapArquivos[registro.foto.id] = registro.arquivo;
    }
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    setState(() {
      _ordemAtual = TipoOrdem.maisRecente;
      fotosSelecionadas.clear();
      fotos = listFotos;
      arquivos = mapArquivos;
      loading = false;
    });
    _ordenarLista(_ordemAtual);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: fotosSelecionadas.isNotEmpty
            ? IconButton(
                onPressed: () {
                  setState(() {
                    fotosSelecionadas.clear();
                  });
                },
                icon: const Icon(Icons.close),
              )
            : null,
        title: Text(
          fotosSelecionadas.isEmpty
              ? 'Galeria'
              : '${fotosSelecionadas.length}  ${fotosSelecionadas.length > 1 ? "selecionadas" : "selecionada"}',
        ),
        actions: [
          IconButton(
            tooltip: 'Sincronizar galeria',
            icon: const Icon(Icons.sync),
            onPressed: () async {
              await _arquivoService.renumerarTodasMissoes();
              await carregarGaleria();
            },
          ),
          if (fotos.length != fotosSelecionadas.length)
            IconButton(
              icon: const Icon(Icons.select_all),
              tooltip: 'Selecionar todas',
              onPressed: () {
                setState(() {
                  fotosSelecionadas = List.from(fotos);
                });
              },
            ),
          if (fotosSelecionadas.isNotEmpty)
            IconButton(
              onPressed: () async {
                final confirmar = await confirmarExclusao(
                  context,
                  mensagem:
                      'Deseja realmente excluir ${fotosSelecionadas.length} foto(s)?',
                );

                if (!confirmar) return;

                await delete.Foto.varias(fotosSelecionadas);
                await carregarGaleria();

                if (fotos.isEmpty) {
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                }
              },
              icon: const Icon(Icons.delete),
            ),
          if (fotosSelecionadas.isNotEmpty)
            IconButton(
              onPressed: () async {
                await ArquivoService.compartilharFotos(fotosSelecionadas);
              },
              icon: Icon(Icons.share, color: Colors.white),
            ),
          PopupMenuButton<TipoOrdem>(
            icon: const Icon(Icons.sort),
            tooltip: 'Mostrar menu',
            onSelected: _ordenarLista,
            itemBuilder: (BuildContext context) => <PopupMenuEntry<TipoOrdem>>[
              const PopupMenuItem<TipoOrdem>(
                value: TipoOrdem.maisRecente,
                child: Text('Mais Recentes'),
              ),
              const PopupMenuItem<TipoOrdem>(
                value: TipoOrdem.maisAntigas,
                child: Text('Mais antigas'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<TipoOrdem>(
                value: TipoOrdem.crescente,
                child: Text('Crescente'),
              ),
              const PopupMenuItem<TipoOrdem>(
                value: TipoOrdem.decrescente,
                child: Text('Decrescente'),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Filtrar por',
            icon: const Icon(Icons.filter_alt),
            onPressed: () async {
              final resultado = await showModalBottomSheet(
                backgroundColor: const Color.fromARGB(255, 25, 35, 55),
                context: context,
                isScrollControlled: true,
                builder: (_) => modal.Filtros(filtro: filtroAtual),
              );
              if (resultado != null) {
                filtroAtual = resultado;
                carregarGaleria();
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (fotos.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma foto econtrada',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(4),
      child: MasonryGridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemCount: fotos.length,
        itemBuilder: (c, index) {
          final foto = fotos[index];
          final arquivo = arquivos[foto.id];
          if (arquivo == null) {
            return const SizedBox.shrink();
          }
          return GestureDetector(
            onLongPress: () {
              setState(() {
                if (fotosSelecionadas.isEmpty) {
                  fotosSelecionadas.add(foto);
                  debugPrint(
                    "OnLongPress-> Fotos selecionadas: ${fotosSelecionadas.length}",
                  );
                }
              });
            },
            onTap: () async {
              final removida = await Navigator.push(
                c,
                PageRouteBuilder(
                  opaque:
                      false, // <-- É isso aqui que deixa o fundo transparente!
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      galeria_foto.Foto(
                        arquivos: arquivos,
                        fotos: fotos,
                        fotosSelecionadas: fotosSelecionadas,
                        initialIndex: index,
                      ),
                ),
              );
              if (removida == true) {
                carregarGaleria();
              }
            },
            child: Thumbnail(
              arquivo: arquivo,
              foto: foto,
              isSelected: fotosSelecionadas.contains(foto),
              isSelectionMode: fotosSelecionadas.isNotEmpty,
              onSelectToggle: () {
                setState(() {
                  if (fotosSelecionadas.contains(foto)) {
                    fotosSelecionadas.remove(foto);
                  } else {
                    fotosSelecionadas.add(foto);
                  }
                });
              },
            ),
          );
        },
      ),
    );
  }
}
