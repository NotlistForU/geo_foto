import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sipam_foto/view/camera/widget/bottom_bar.dart' as widgets;
import 'package:sipam_foto/view/camera/widget/preview.dart' as widgets;

const double height = widgets.BottomBar.height;
Widget cameraPronta({
  required File? fotoTemporaria,
  required CameraController controller,
  required GlobalKey repaintKey,
  required VoidCallback onFoto,
  required VoidCallback onMaps,
  required bool abrirMaps,
}) {
  return Scaffold(
    appBar: AppBar(title: const Text('Câmera')),
    body: Stack(
      children: [
        Positioned.fill(
          bottom: height,
          child: widgets.Preview(
            imageFile: fotoTemporaria,
            preview: CameraPreview(controller),
            dados: 'Teste',
            repaintKey: repaintKey,
            lat: -8.7619,
            lng: -63.9039,
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
