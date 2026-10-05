import 'package:sipam_foto/database/create.dart';

class MissaoModel {
  final int id;
  final DateTime data;
  final String nome;
  final bool ativa;
  MissaoModel({
    required this.id,
    required this.data,
    required this.nome,
    required this.ativa,
  });

  factory MissaoModel.fromMap(Map<String, dynamic> map) {
    return MissaoModel(
      id: map['id'] as int,
      data: DateTime.fromMillisecondsSinceEpoch(map['data_criacao'] as int),
      nome: map['nome'] as String,
      ativa: (map['ativa'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data_criacao': data.millisecondsSinceEpoch,
      'nome': nome,
      'ativa': ativa ? 1 : 0,
    };
  }

  MissaoModel copyWith({int? id, DateTime? data, String? nome, bool? ativa}) {
    return MissaoModel(
      id: id ?? this.id,
      data: data ?? this.data,
      nome: nome ?? this.nome,
      ativa: ativa ?? this.ativa,
    );
  }

  // =========================
  // REPOSITORY
  // =========================

  static Future<int> inserir(MissaoModel missao) async {
    final db = await Create.database;

    return await db.insert('missoes', missao.toMap());
  }

  static Future<MissaoModel?> buscarPorId(int id) async {
    final db = await Create.database;

    final resultado = await db.query(
      'missoes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return MissaoModel.fromMap(resultado.first);
  }

  static Future<List<MissaoModel>> listar() async {
    final db = await Create.database;

    final resultado = await db.query('missoes', orderBy: 'data_criacao DESC');

    return resultado.map((map) => MissaoModel.fromMap(map)).toList();
  }

  static Future<int> atualizar(MissaoModel missao) async {
    final db = await Create.database;

    return await db.update(
      'missoes',
      missao.toMap(),
      where: 'id = ?',
      whereArgs: [missao.id],
    );
  }

  static Future<int> excluir(int id) async {
    final db = await Create.database;

    return await db.delete('missoes', where: 'id = ?', whereArgs: [id]);
  }

  static Future<MissaoModel?> buscarAtiva() async {
    final db = await Create.database;

    final resultado = await db.query(
      'missoes',
      where: 'ativa = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return MissaoModel.fromMap(resultado.first);
  }
}
