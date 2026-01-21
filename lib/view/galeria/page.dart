import 'package:flutter/material.dart';
import 'package:sipam_foto/view/galeria/foto.dart' as photo_view;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sipam_foto/model/foto.dart' as model;
import 'package:sipam_foto/database/fotos/select.dart' as select;
import 'package:sipam_foto/view/galeria/thumbnail.dart';

class Galeria extends StatefulWidget {
  const Galeria({super.key});
  @override
  State<Galeria> createState() => _GaleriaState();
}

class _GaleriaState extends State<Galeria> {
  bool loading = true;
  List<model.Foto> fotos = [];
  Map<String, AssetEntity> assets = {};

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

    fotos = await select.Foto.todasFotos();
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
          IconButton(icon: const Icon(Icons.filter_alt), onPressed: () {}),
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
        itemBuilder: (context, index) {
          final foto = fotos[index];
          final asset = assets[foto.assetId];
          if (asset == null) {
            return const SizedBox.shrink();
          }
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => photo_view.Foto(asset: asset),
                ),
              );
            },
            child: Thumbnail(asset: asset, foto: foto),
          );
        },
      ),
    );
  }
}
