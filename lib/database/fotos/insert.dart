import '../create.dart';

class Foto {
  static Future<void> values({
    required int missaoId,
    required int numero,
    required String nome,
    double? latitude,
    double? longitude,
    double? altitude,
  }) async {
    final db = await Create.database;
    await db.insert('fotos', {
      'missao_id': missaoId,
      'numero': numero,
      'nome': nome,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'data_criacao': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
