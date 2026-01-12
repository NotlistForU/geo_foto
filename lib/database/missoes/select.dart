import 'package:sipam_foto/database/create.dart';
import 'package:sipam_foto/database/util/querys.dart';
import 'package:sipam_foto/model/missao.dart';

class Select {
  static Future<Missao?> missaoAtiva() async {
    final db = await Create.database;
    final missao = await isAtiva(db);
    return Missao(
      id: missao['id'] as int,
      contador: missao['contador'] as int,
      data: DateTime.fromMillisecondsSinceEpoch(missao['data_criacao'] as int),
      nome: missao['nome'] as String,
      ativa: true,
    );
  }
}
