import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sipam_foto/view/galeria/galeria.dart';

class BottomBar extends StatelessWidget {
  final File? fotoTemporaria;
  final VoidCallback onFoto;
  final VoidCallback onMaps;
  final bool abrirMaps;
  static const double height = 110;
  const BottomBar({
    super.key,
    required this.fotoTemporaria,
    required this.onFoto,
    required this.onMaps,
    required this.abrirMaps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white12, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Galeria
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Galeria()),
              );
            },
            icon: fotoTemporaria == null
                ? const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                    size: 30,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      fotoTemporaria!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
          ),

          // Botao de tirar foto
          GestureDetector(
            onTap: onFoto,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          // botao do google maps
          IconButton(
            onPressed: abrirMaps ? onMaps : null,
            icon: Icon(
              Icons.public,
              color: abrirMaps ? Colors.white : Colors.white24,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}
