import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sipam_foto/view/galeria/foto.dart' as galeria_foto;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sipam_foto/model/foto.dart' as model;
import 'package:sipam_foto/model/filtro.dart' as model;
import 'package:sipam_foto/database/fotos/select.dart' as select;
import 'package:sipam_foto/database/fotos/delete.dart' as delete;
import 'package:sipam_foto/view/galeria/thumbnail.dart';
import 'package:sipam_foto/view/galeria/modal.dart' as modal;

class Galeria extends StatefulWidget {
  const Galeria({super.key});
  @override
  State<Galeria> createState() => _GaleriaState();
}

enum TipoOrdem { maisRecente, maisAntigas, nomeAz, nomeZa }

class _GaleriaState extends State<Galeria> {
  TipoOrdem _ordemAtual = TipoOrdem.maisRecente;
  bool loading = true;
  List<model.Foto> fotos = [];
  List<model.Foto> fotosSelecionadas = [];
  Map<String, AssetEntity> assets = {};
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
        case TipoOrdem.nomeAz:
          fotos.sort((a, b) => a.nome.compareTo(b.nome));
          break;
        case TipoOrdem.nomeZa:
          fotos.sort((a, b) => b.nome.compareTo(a.nome));
          break;
      }
    });
  }

  Future<void> carregarGaleria() async {
    setState(() => loading = true);
    final permissao = await PhotoManager.requestPermissionExtend();
    if (!permissao.isAuth) {
      setState(() {
        setState(() => loading = false);
        return;
      });
    }
    await PhotoManager.clearFileCache();
    await PhotoManager.releaseCache();

    fotos = await select.Foto.filtro(filtroAtual);

    final Map<String, AssetEntity> temp = {};

    List<model.Foto> fotosValidas = [];

    for (final foto in fotos) {
      final asset = await AssetEntity.fromId(foto.assetId);
      if (asset != null) {
        temp[foto.assetId] = asset;
        fotosValidas.add(foto);
      } else {
        await delete.Foto.uma(foto);
      }
    }

    assets = temp;
    fotos = fotosValidas;

    setState(() => loading = false);
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
                await delete.Foto.varias(fotosSelecionadas);
                if (fotos.isEmpty) {
                  if (context.mounted) {
                    Navigator.pop(context, true);
                  }
                }
              },
              icon: const Icon(Icons.delete),
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
                value: TipoOrdem.nomeAz,
                child: Text('Nome (A-Z)'),
              ),
              const PopupMenuItem<TipoOrdem>(
                value: TipoOrdem.nomeZa,
                child: Text('Nome (Z-A)'),
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
          final asset = assets[foto.assetId];
          if (asset == null) {
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
                        assets: assets,
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
              asset: asset,
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
