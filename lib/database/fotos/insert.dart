import '../create.dart';

class Foto {
  static Future<void> values({
    required int missaoid,
    required int numero,
    required String nome,
    required String assetId,
    double? latitude,
    double? longitude,
    double? altitude,
  }) async {
    final db = await Create.database;
    await db.insert('fotos', {
      'missao_id': missaoid,
      'numero': numero,
      'nome': nome,
      'asset_id': assetId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'data_criacao': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
