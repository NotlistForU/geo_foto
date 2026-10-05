import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:extended_image/extended_image.dart';
import 'package:sipam_foto/model/foto.dart' as model;
import 'package:sipam_foto/database/fotos/delete.dart' as delete;
import 'package:sipam_foto/view/galeria/utils.dart';
import 'package:sipam_foto/service/foto_service.dart' as service;

class Foto extends StatefulWidget {
  final Map<int, File> arquivos;
  final List<model.Foto> fotos;
  final int initialIndex;
  final List<model.Foto> fotosSelecionadas;
  const Foto({
    super.key,
    required this.arquivos,
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
    final dataFormatada = DateFormat('dd MMM yyyy').format(fotoAtual.data);
    final horaFormatada = DateFormat('HH:mm').format(fotoAtual.data);
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
          title: widget.fotosSelecionadas.isNotEmpty
              ? Text(
                  '${widget.fotosSelecionadas.length} '
                  '${widget.fotosSelecionadas.length > 1 ? "selecionadas" : "selecionada"}',
                )
              : Row(
                  children: [
                    // ESQUERDA (data + hora)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dataFormatada, style: TextStyle(fontSize: 14)),
                        Text(
                          horaFormatada,
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                    Spacer(),
                    Expanded(
                      child: Text(
                        fotoAtual.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
            final arquivo = widget.arquivos[foto.id];

            if (arquivo == null) return const SizedBox.shrink();

            // Removemos o AnimatedBuilder e retornamos o ExtendedImage direto!
            return ExtendedImage(
              image: FileImage(arquivo),
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
                  await service.FotoService.compartilharFotos([fotoAtual]);
                },
                icon: Icon(Icons.share, color: Colors.white),
              ),

              IconButton(
                onPressed: () async {
                  final confirmar = await confirmarExclusao(context);
                  if (!confirmar) return;
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
