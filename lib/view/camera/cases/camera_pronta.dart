import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sipam_foto/model/localizacao.dart' as model;
import 'package:sipam_foto/view/camera/widget/bottom_bar.dart' as widgets;
import 'package:sipam_foto/view/camera/widget/preview.dart' as widgets;

const double height = widgets.BottomBar.height;
Widget cameraPronta({
  required bool feedback,
  required File? fotoTemporaria,
  required CameraController controller,
  required GlobalKey repaintKey,
  required VoidCallback onFoto,
  required VoidCallback onMaps,
  required bool abrirMaps,
  required model.Localizacao? localizacaoAtual,
}) {
  return Scaffold(
    appBar: AppBar(title: const Text('Câmera')),
    body: Stack(
      children: [
        Positioned.fill(
          bottom: height,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            decoration: BoxDecoration(
              border: feedback
                  ? Border.all(color: Colors.white, width: 6)
                  : null,
            ),
            child: widgets.Preview(
              imageFile: fotoTemporaria,
              preview: CameraPreview(controller),
              dados: localizacaoAtual?.dados ?? 'Obtendo GPS...',
              repaintKey: repaintKey,
              lat: localizacaoAtual?.latitude,
              lng: localizacaoAtual?.longitude,
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: widgets.BottomBar(
            fotoTemporaria: fotoTemporaria,
            onFoto: onFoto,
            onMaps: onMaps,
            abrirMaps: abrirMaps,
          ),
        ),
      ],
    ),
  );
}
