import 'package:sipam_foto/database/create.dart';
import 'package:sipam_foto/database/util/queries.dart';
import 'package:sipam_foto/model/missao.dart' as model;

class Missao {
  static Future<model.Missao?> missaoAtiva() async {
    final db = await Create.database;
    final missao = await isAtiva(db);
    return model.Missao(
      id: missao['id'] as int,
      contador: missao['contador'] as int,
      data: DateTime.fromMillisecondsSinceEpoch(missao['data_criacao'] as int),
      nome: missao['nome'] as String,
      ativa: true,
    );
  }

  static Future<List<model.Missao>> todasMissoes() async {
    final db = await Create.database;
    final result = await db.query('missoes', orderBy: 'data_criacao DESC');
    return result.map((e) {
      return model.Missao(
        id: e['id'] as int,
        contador: e['contador'] as int,
        data: DateTime.fromMillisecondsSinceEpoch(e['data_criacao'] as int),
        nome: e['nome'] as String,
        ativa: (e['ativa'] as int) == 1,
      );
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
