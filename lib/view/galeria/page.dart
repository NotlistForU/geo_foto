import 'package:flutter/material.dart';
import 'package:sipam_foto/view/galeria/foto.dart' as galeria_foto;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sipam_foto/model/foto.dart' as model;
import 'package:sipam_foto/model/filtro.dart' as model;
import 'package:sipam_foto/database/fotos/select.dart' as select;
import 'package:sipam_foto/view/galeria/thumbnail.dart';
import 'package:sipam_foto/view/galeria/modal.dart' as modal;

class Galeria extends StatefulWidget {
  const Galeria({super.key});
  @override
  State<Galeria> createState() => _GaleriaState();
}

class _GaleriaState extends State<Galeria> {
  bool loading = true;
  List<model.Foto> fotos = [];
  Map<String, AssetEntity> assets = {};
  model.Filtro filtroAtual = model.Filtro.empty;

  @override
  void initState() {
    super.initState();
    carregarGaleria();
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
    final ids = fotos.map((f) => f.assetId).toList();
    final Map<String, AssetEntity> temp = {};
    for (final id in ids) {
      final asset = await AssetEntity.fromId(id);
      if (asset != null) {
        temp[id] = asset;
      }
    }
    assets = temp;

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galeria'),
        actions: [
          IconButton(
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
            onTap: () async {
              final removida = await Navigator.push(
                c,
                MaterialPageRoute(
                  builder: (_) => galeria_foto.Foto(
                    assets: assets,
                    fotos: fotos,
                    initialIndex: index,
                  ),
                ),
              );
              if (removida == true) {
                carregarGaleria();
              }
            },
            child: Thumbnail(asset: asset, foto: foto),
          );
        },
      ),
    );
  }
}
