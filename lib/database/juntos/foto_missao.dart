import 'package:sipam_foto/database/create.dart';
import 'package:sipam_foto/database/util/queries.dart';
import 'package:sipam_foto/database/missoes/update.dart' as update;
import 'package:sipam_foto/database/missoes/insert.dart' as insert;
import 'package:sipam_foto/database/missoes/select.dart' as select;
import 'package:sipam_foto/database/missoes/delete.dart' as delete;
import 'package:sipam_foto/database/fotos/select.dart' as select;
import 'package:sipam_foto/database/fotos/delete.dart' as delete;
import 'package:sipam_foto/database/fotos/insert.dart' as insert;

class FotoMissao {
  final int missaoid;
  final String nomeArquivo;

  FotoMissao({required this.missaoid, required this.nomeArquivo});

  static String rotulo(String nome, int num) {
    final temp = num.toString().padLeft(2, '0');
    return '${nome.toLowerCase().replaceAll(' ', '_')}-$temp';
  }

  static Future<FotoMissao> gerar(bool preencherLacunas) async {
    final db = await Create.database;
    final missao = await isAtiva(db);

    final missaoId = missao['id'] as int;
    final nome = missao['nome'] as String;

    int num = await getProximoNumero(
      missaoId: missaoId,
      preencherLacunas: preencherLacunas,
    );

    return FotoMissao(
      missaoid: missaoId,
      nomeArquivo: FotoMissao.rotulo(nome, num),
    );
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

  static Future<int> proximoNumeroPreenchendo(int missaoId) async {
    final db = await Create.database;

    final result = await db.query(
      'fotos',
      columns: ['numero'],
      where: 'missao_id = ?',
      whereArgs: [missaoId],
      orderBy: 'numero ASC',
    );

    int esperado = 1;

    for (final row in result) {
      final numero = row['numero'] as int;

      if (numero != esperado) {
        return esperado;
      }

      esperado++;
    }
    return esperado;
  }

  static Future<int> getProximoNumero({
    required int missaoId,
    required bool preencherLacunas,
  }) async {
    if (preencherLacunas) {
      return proximoNumeroPreenchendo(missaoId);
    } else {
      return proximoNumeroSequencial(missaoId);
    }
  }
}
