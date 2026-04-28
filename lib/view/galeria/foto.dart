import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final List<model.Foto> fotosSelecionadas;
  const Foto({
    super.key,
    required this.assets,
    required this.fotos,
    required this.initialIndex,
    required this.fotosSelecionadas,
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
    final dataFormatada = DateFormat('dd/MM/yyyy').format(fotoAtual.data);

    return ExtendedImageSlidePage(
      key: const Key('tela_foto_slide'),
      slidePageBackgroundHandler: (offset, pageSize) {
        double opacity =
            1.0 -
            offset.distance /
                (Offset(pageSize.width, pageSize.height).distance / 2.0);
        return Colors.black.withValues(alpha: opacity.clamp(0.0, 1.0));
      },
      slideAxis: SlideAxis.both,
      slideType: SlideType.onlyImage,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Obrigatório ser transparente
        extendBodyBehindAppBar: true,
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.3),
          title: Text(
            widget.fotosSelecionadas.isNotEmpty
                ? '${widget.fotosSelecionadas.length}  ${widget.fotosSelecionadas.length > 1 ? "selecionadas" : "selecionada"}'
                : dataFormatada,
          ),
          elevation: 0,
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

            // Removemos o AnimatedBuilder e retornamos o ExtendedImage direto!
            return ExtendedImage(
              image: AssetEntityImageProvider(asset, isOriginal: true),
              fit: BoxFit.contain,
              mode: ExtendedImageMode.gesture,
              enableSlideOutPage: true, // <-- ESSENCIAL PARA FUNCIONAR
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
          },
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.black.withValues(alpha: 0.3),
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
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
        ),
      ),
    );
  }
}
