import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_view/photo_view.dart';
import 'package:extended_image/extended_image.dart';
import 'package:sipam_foto/model/foto.dart' as model;
import 'package:sipam_foto/database/fotos/delete.dart' as delete;
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

class Foto extends StatefulWidget {
  final Map<String, AssetEntity> assets;
  final List<model.Foto> fotos;
  final int initialIndex;
  const Foto({
    super.key,
    required this.assets,
    required this.fotos,
    required this.initialIndex,
  });

  @override
  State<Foto> createState() => _FotoState();
}

class _FotoState extends State<Foto> {
  late ExtendedPageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = ExtendedPageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fotoAtual = widget.fotos[_currentIndex];

    return Dismissible(
      key: const Key('tela_foto_dismiss'),
      direction: DismissDirection.vertical,
      onDismissed: (direction) {
        Navigator.pop(context, false);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () async {
                await delete.Foto.uma(fotoAtual);
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.delete, color: Colors.white),
            ),
          ],
        ),
        body: ExtendedImageGesturePageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          itemCount: widget.fotos.length,
          itemBuilder: (context, index) {
            final foto = widget.fotos[index];
            final asset = widget.assets[foto.assetId];

            if (asset == null) return const SizedBox.shrink();

            return AnimatedBuilder(
              animation: _pageController,
              builder: (context, child) {
                double value = 0.0;
                if (_pageController.position.haveDimensions) {
                  value = _pageController.page! - index;
                } else {
                  value = (_currentIndex - index).toDouble();
                }

                Widget extendedImage = ExtendedImage(
                  image: AssetEntityImageProvider(asset, isOriginal: true),
                  fit: BoxFit.contain,
                  mode: ExtendedImageMode.gesture,
                  initGestureConfigHandler: (state) {
                    return GestureConfig(
                      minScale: 1.0,
                      animationMinScale: 0.8,
                      maxScale: 3.0,
                      animationMaxScale: 3.5,
                      speed: 1.0,
                      inertialSpeed: 100.0,
                      initialScale: 1.0,
                      inPageView: true,
                    );
                  },
                );

                if (value > 0) {
                  return Transform.translate(
                    offset: Offset(
                      value * MediaQuery.of(context).size.width,
                      0,
                    ),
                    child: Transform.scale(
                      scale: 1.0 - (value * 0.15),
                      child: extendedImage,
                    ),
                  );
                }
                return extendedImage;
              },
            );
          },
        ),
      ),
    );
  }
}
