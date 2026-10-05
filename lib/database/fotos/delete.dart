import 'dart:io';

import 'package:photo_manager/photo_manager.dart';
import 'package:sipam_foto/database/create.dart';
import 'package:sipam_foto/model/foto.dart' as model;
import 'package:sipam_foto/service/foto_service.dart' as service;

class Foto {
  static Future<void> uma(model.Foto foto) async {
    await varias([foto]);
  }

  static Future<void> varias(List<model.Foto> fotos) async {
    if (fotos.isEmpty) return;

    final service.FotoService fotoService = service.FotoService();

    // Apagar arquivos físicos
    for (final foto in fotos) {
      final arquivo = await service.FotoService.getFoto(foto);
      if (arquivo != null) {
        await arquivo.delete();
      }
    }

    // Apagar fotos no banco de dados
    final db = await Create.database;
    final batch = db.batch();
    for (final foto in fotos) {
      // apaga no banco
      batch.delete('fotos', where: 'id = ?', whereArgs: [foto.id]);
    }
    await batch.commit(noResult: true);

    // Pega os ID's das missões das fotos selecionadas.
    List<int> idMissoesAfetadas = [];
    for (final foto in fotos) {
      // Não repete ID
      if (idMissoesAfetadas.contains(foto.missaoId)) continue;
      idMissoesAfetadas.add(foto.missaoId);
    }

    // Para cada missão, reenumera as fotos.
    for (final missaoId in idMissoesAfetadas) {
      await fotoService.renumerarFotos(missaoId);
    }
  }
}
