import 'package:sipam_foto/database/create.dart';
import 'package:sipam_foto/database/util/queries.dart';
import 'package:sipam_foto/model/missao.dart' as model;

class Missao {
  static Future<model.Missao?> getMissaoById(int missaoId) async {
    final db = await Create.database;

    final result = await db.query(
      'missoes',
      where: 'id = ?',
      whereArgs: [missaoId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return model.Missao.fromMap(result.first);
  }

  static Future<model.Missao?> missaoAtiva() async {
    final db = await Create.database;
    final missao = await isAtiva(db);
    return model.Missao.fromMap(missao);
  }

  static Future<List<model.Missao>> todasMissoes() async {
    final db = await Create.database;
    final result = await db.query('missoes', orderBy: 'data_criacao DESC');
    return result.map((e) {
      return model.Missao.fromMap(e);
    }).toList();
  }

  static Future<bool> existeMissao(String nome) async {
    final db = await Create.database;
    final result = await db.query(
      'missoes',
      where: 'LOWER(nome) = ?',
      whereArgs: [nome.toLowerCase()],
      limit: 1,
    );
    return result.isEmpty;
  }
}
