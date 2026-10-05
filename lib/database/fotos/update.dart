import 'package:sipam_foto/database/create.dart';

class Foto {
  static Future<void> numeroEnome({
    required int id,
    required int numero,
    required String nome,
  }) async {
    final db = await Create.database;
    await db.update(
      'fotos',
      {'numero': numero, 'nome': nome},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
