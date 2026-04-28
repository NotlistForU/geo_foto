import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:sipam_foto/model/foto.dart' as model;

class Thumbnail extends StatelessWidget {
  final AssetEntity asset;
  final model.Foto foto;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onSelectToggle;
  const Thumbnail({
    super.key,
    required this.asset,
    required this.foto,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    final dataFormatada = DateFormat('dd/MM/yyyy').format(foto.data);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Container(
        decoration: BoxDecoration(
          border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
        ),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            children: [
              // 🖼️ imagem SEMPRE presente
              Positioned.fill(
                child: AssetEntityImage(
                  asset,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize.square(300),
                  fit: BoxFit.cover,
                ),
              ),

              // 🔵 overlay de seleção (opcional, mas bonito)
              if (isSelected)
                Positioned.fill(
                  child: Container(color: Colors.blue.withOpacity(0.2)),
                ),

              // ☑️ bolinha no canto
              if (isSelectionMode)
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: onSelectToggle,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? Colors.blue : Colors.black45,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),

              // 📅 gradiente + texto (fica por cima da imagem)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        foto.nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        dataFormatada,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
