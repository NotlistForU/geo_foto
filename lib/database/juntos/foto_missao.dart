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

  static Future<FotoMissao> gerar() async {
    final db = await Create.database;
    final missao = await isAtiva(db);

    final missaoid = missao['id'] as int;
    final nome = missao['nome'] as String;

    final num = await update.Missao.incrementarContador();

    return FotoMissao(
      missaoid: missaoid,
      nomeArquivo: FotoMissao.rotulo(nome, num),
    );
  }
}
