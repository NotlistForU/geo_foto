import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sipam_foto/model/mapa_model.dart';
import 'package:sipam_foto/database/create.dart';
import 'package:sipam_foto/model/ponto_model.dart';

class MapaImporter {
  /// Abre o seletor e valida o ZIP SEM gravar nada.
  /// Retorna null se o usuário cancelar. Lança [FormatException] se for inválido.
  static Future<ZipMapa?> ler() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    final zipPath = picked?.files.single.path;
    if (zipPath == null) return null;

    try {
      final Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(await File(zipPath).readAsBytes());
      } catch (_) {
        throw const FormatException('o arquivo não é um ZIP válido');
      }

      final jsonFile = archive.files
          .where((f) => f.isFile && f.name.toLowerCase().endsWith('.json'))
          .firstOrNull;
      if (jsonFile == null) throw const FormatException('o ZIP não tem JSON');

      final String imageName;
      final List<LatLng> cantos = [];
      final Map<String, List<PontoImportado>> camadas = {};
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
          cantos.add(MapaModel.canto(corners[key]));
        }

        final vetores = (meta['vetores'] as Map<String, dynamic>?) ?? {};
        vetores.forEach((nomeCamada, lista) {
          camadas[nomeCamada] = (lista as List).map((e) {
            final item = e as Map<String, dynamic>;
            final props = Map<String, dynamic>.from(
              item['propriedades'] as Map,
            );
            final nome = props['nome_ponto']?.toString().trim();
            return PontoImportado(
              nome: (nome == null || nome.isEmpty) ? null : nome,
              propriedades: props,
              posicao: MapaModel.canto(item['coordenadas']),
            );
          }).toList();
        });
      } catch (_) {
        throw const FormatException('JSON fora do formato esperado');
      }

      final pngFile = archive.files
          .where((f) => f.isFile && p.basename(f.name) == imageName)
          .firstOrNull;
      if (pngFile == null) {
        throw FormatException('o ZIP não tem o PNG "$imageName"');
      }

      return ZipMapa(
        imageName: imageName,
        pngBytes: pngFile.content as List<int>,
        upperLeft: cantos[0],
        upperRight: cantos[1],
        lowerRight: cantos[2],
        lowerLeft: cantos[3],
        camadas: camadas,
      );
    } finally {
      final zip = File(zipPath);
      if (await zip.exists()) await zip.delete();
    }
  }

  /// Grava o PNG no armazenamento do app e devolve o caminho.
  static Future<String> salvarPng(ZipMapa zip) async {
    final docs = await getApplicationDocumentsDirectory();
    final dest = File(
      p.join(
        docs.path,
        'mapas',
        '${DateTime.now().millisecondsSinceEpoch}_${zip.imageName}',
      ),
    );
    await dest.create(recursive: true);
    await dest.writeAsBytes(zip.pngBytes);
    return dest.path;
  }

  /// Quantos pontos de campo e fotos a missão tem hoje.
  static Future<ResumoMissao> resumo(int missaoId) async {
    final db = await Create.database;

    final p = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM pontos WHERE missao_id = ? AND camada IS NULL',
      [missaoId],
    );
    final f = await db.rawQuery(
      'SELECT COUNT(*) AS n FROM fotos '
      'WHERE ponto_id IN (SELECT id FROM pontos WHERE missao_id = ?)',
      [missaoId],
    );

    return ResumoMissao(p.first['n'] as int, f.first['n'] as int);
  }

  /// Troca o mapa e os pontos da missão numa transação só.
  static Future<void> gravar({
    required int missaoId,
    required ZipMapa zip,
    required String pngPath,
    required List<String> camadas,
  }) async {
    final db = await Create.database;

    final mapa = MapaModel(
      id: 0,
      missaoId: missaoId,
      imagePath: pngPath,
      upperLeft: zip.upperLeft,
      upperRight: zip.upperRight,
      lowerLeft: zip.lowerLeft,
      lowerRight: zip.lowerRight,
    );

    await db.transaction((txn) async {
      await txn.delete('mapas', where: 'missao_id = ?', whereArgs: [missaoId]);
      // as fotos saem junto, pelo ON DELETE CASCADE
      await txn.delete('pontos', where: 'missao_id = ?', whereArgs: [missaoId]);

      await txn.insert('mapas', mapa.toMap());

      var numero = 1;
      for (final camada in camadas) {
        for (final pt in zip.camadas[camada] ?? <PontoImportado>[]) {
          final ponto = PontoModel(
            id: 0,
            missaoId: missaoId,
            numero: numero,
            data: DateTime.now(),
            nome: pt.nome ?? 'Ponto $numero',
            latitude: pt.posicao.latitude,
            longitude: pt.posicao.longitude,
            altitude: null,
            camada: camada,
            propriedades: pt.propriedades,
          );
          await txn.insert('pontos', ponto.toMap());
          numero++;
        }
      }
    });
  }
}

class PontoImportado {
  final String? nome; // null = o app usa "Ponto <ID>"
  final Map<String, dynamic> propriedades;
  final LatLng posicao;

  const PontoImportado({
    required this.nome,
    required this.propriedades,
    required this.posicao,
  });
}

class ZipMapa {
  final String imageName;
  final List<int> pngBytes;
  final LatLng upperLeft, upperRight, lowerRight, lowerLeft;
  final Map<String, List<PontoImportado>> camadas;

  const ZipMapa({
    required this.imageName,
    required this.pngBytes,
    required this.upperLeft,
    required this.upperRight,
    required this.lowerRight,
    required this.lowerLeft,
    required this.camadas,
  });
}

class ResumoMissao {
  final int pontosManuais;
  final int fotos;
  const ResumoMissao(this.pontosManuais, this.fotos);
}
