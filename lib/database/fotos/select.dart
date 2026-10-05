import 'package:sipam_foto/database/create.dart';
import 'package:sipam_foto/database/util/filtrar.dart';
import 'package:sipam_foto/model/filtro.dart' as model;
import 'package:sipam_foto/model/foto.dart' as model;

class Foto {
  static Future<List<model.Foto>> todasFotos() async {
    final db = await Create.database;
    final result = await db.query('fotos', orderBy: 'data_criacao');
    return result.map((e) => model.Foto.fromMap(e)).toList();
  }

  static Future<int> proximoNumeroSequencial(int missaoId) async {
    final db = await Create.database;

    final result = await db.rawQuery(
      'SELECT MAX(numero) as max FROM fotos WHERE missao_id =?',
      [missaoId],
    );

    final max = result.first['max'] as int?;

    return (max ?? 0) + 1;
  }

  static Future<List<model.Foto>> filtro(model.Filtro filtro) async {
    // FILTRO POR...
    final db = await Create.database;
    final where = <String>[];
    final args = <Object>[];
    if (filtro.isEmpty) {
      return todasFotos();
    }

    // MISSÃO
    filtrar(where, args, 'missao_id = ?', filtro.missaoid);

    // NOME
    filtrar(
      where,
      args,
      'LOWER(nome) LIKE ?',
      filtro.nome?.isNotEmpty == true
          ? '%${filtro.nome!.toLowerCase()}%'
          : null,
    );
    // DATA INICIAL
    filtrar(
      where,
      args,
      'data_criacao >= ?',
      filtro.inicio?.millisecondsSinceEpoch,
    );
    // DATA FINAL
    if (filtro.fim != null) {
      final diaTotal = DateTime(
        filtro.fim!.year,
        filtro.fim!.month,
        filtro.fim!.day,
        23,
        59,
        59,
      );
      filtrar(
        where,
        args,
        'data_criacao <= ?',
        diaTotal.millisecondsSinceEpoch,
      );
    }

    // ALTITUDE MÍNIMA
    filtrar(where, args, 'altitude >= ?', filtro.minimo);
    // ALTITUDE MÁXIMA
    filtrar(where, args, 'altitude <= ?', filtro.maximo);

    // consulta final
    final result = await db.query(
      'fotos',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args,
      orderBy: 'data_criacao DESC',
    );

    return result.map((e) => model.Foto.fromMap(e)).toList();
  }

  static Future<List<model.Foto>> porIdMissao(int missaoId) async {
    final db = await Create.database;

    final result = await db.query(
      'fotos',
      where: 'missao_id = ?',
      whereArgs: [missaoId],
      orderBy: 'numero ASC',
    );

    return result.map((e) => model.Foto.fromMap(e)).toList();
  }
}
