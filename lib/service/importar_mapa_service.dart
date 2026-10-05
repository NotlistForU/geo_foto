import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MapaImportado {
  final String imagePath;
  final double south, west, north, east;

  const MapaImportado({
    required this.imagePath,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });
}

class MapaImporter {
  /// Abre o seletor, valida o ZIP (PNG + JSON), copia o PNG pra pasta do app
  /// e devolve o caminho + bounds.
  /// Retorna null se o usuário cancelar. Lança [FormatException] se o ZIP for inválido.
  static Future<MapaImportado?> importar() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final zipPath = picked?.files.single.path;
    if (zipPath == null) return null;

    try {
      // 1. Abre o ZIP
      final Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(await File(zipPath).readAsBytes());
      } catch (_) {
        throw const FormatException('o arquivo não é um ZIP válido');
      }

      // 2. Acha e lê o JSON
      final jsonFile = archive.files
          .where((f) => f.isFile && f.name.toLowerCase().endsWith('.json'))
          .firstOrNull;
      if (jsonFile == null) throw const FormatException('o ZIP não tem JSON');

      final String imageName;
      final List<double> lats = [];
      final List<double> lons = [];
      try {
        final meta =
            jsonDecode(utf8.decode(jsonFile.content as List<int>))
                as Map<String, dynamic>;
        imageName = p.basename(meta['image'] as String);

        final corners = meta['corners'] as Map<String, dynamic>;
        for (final key in [
          'upperLeft',
          'upperRight',
          'lowerRight',
          'lowerLeft',
        ]) {
          final c = corners[key] as List; // no JSON vem [lon, lat]
          lons.add((c[0] as num).toDouble());
          lats.add((c[1] as num).toDouble());
        }
      } catch (_) {
        throw const FormatException('JSON fora do formato esperado');
      }

      // 3. Acha o PNG que o JSON referencia
      final pngFile = archive.files
          .where((f) => f.isFile && p.basename(f.name) == imageName)
          .firstOrNull;
      if (pngFile == null) {
        throw FormatException('o ZIP não tem o PNG "$imageName"');
      }

      // 4. Copia o PNG pro armazenamento do app (uso offline)
      final docs = await getApplicationDocumentsDirectory();
      final dest = File(
        p.join(
          docs.path,
          'mapas',
          '${DateTime.now().millisecondsSinceEpoch}_$imageName',
        ),
      );
      await dest.create(recursive: true);
      await dest.writeAsBytes(pngFile.content as List<int>);

      return MapaImportado(
        imagePath: dest.path,
        south: lats.reduce(min),
        north: lats.reduce(max),
        west: lons.reduce(min),
        east: lons.reduce(max),
      );
    } finally {
      // Apaga a cópia do ZIP que o file_picker deixou no cache
      final zip = File(zipPath);
      if (await zip.exists()) await zip.delete();
    }
  }
}
