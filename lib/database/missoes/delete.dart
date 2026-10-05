import 'dart:io';
import 'package:flutter/foundation.dart'; // Para debugPrint
import 'package:path_provider/path_provider.dart';
import 'package:sipam_foto/database/create.dart';
import 'package:sipam_foto/model/missao.dart' as model;
import 'package:sipam_foto/model/foto.dart' as model;
import 'package:sipam_foto/database/fotos/delete.dart' as delete;

class Missao {
  static Future<void> deletarUmaMissao(model.Missao missao) async {
    final db = await Create.database;

    final fotosRows = await db.query(
      'fotos',
      where: 'missao_id = ?',
      whereArgs: [missao.id],
    );

    final List<model.Foto> fotos = [];
    for (Map<String, Object?> foto in fotosRows) {
      final fotoObjeto = model.Foto.fromMap(foto);
      fotos.add(fotoObjeto);
    }

    await delete.Foto.varias(fotos);

    final diretorioBase = await getExternalStorageDirectory();
    if (diretorioBase != null) {
      final diretorioMissao = Directory(
        '${diretorioBase.path}/Sipam-${missao.id}',
      );
      if (await diretorioMissao.exists()) {
        await diretorioMissao.delete(recursive: true);
      }
    }

    await db.delete('missoes', where: 'id =?', whereArgs: [missao.id]);
  }

  static Future<void> missao(model.Missao missao) async {
    DebugPrintCallback debugPrint = debugPrintThrottled;
    final db = await Create.database;
    if (missao.ativa) {
      throw Exception('Desative a missão para poder excluir.');
    }
    final fotos = await db.query(
      'fotos',
      columns: ['path'],
      where: 'missao_id = ?',
      whereArgs: [missao.id],
    );
    for (final foto in fotos) {
      final path = foto['path'] as String;
      final file = File(path);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (erro) {
          debugPrint('Erro ao apagar arquivo $path');
        }
      }
    }
    await db.delete('fotos', where: 'missao_id = ?', whereArgs: [missao.id]);
    await db.delete("missoes", where: 'id = ?', whereArgs: [missao.id]);
  }
}
