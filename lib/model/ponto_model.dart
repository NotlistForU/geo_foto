import 'package:sipam_foto/database/create.dart';
import 'dart:convert';

class PontoModel {
  final int id;
  final int missaoId;
  final int numero;
  final DateTime data;
  final String nome;
  final double latitude;
  final double longitude;
  final double? altitude;
  final String? camada;
  final Map<String, dynamic>? propriedades;

  const PontoModel({
    required this.id,
    required this.missaoId,
    required this.numero,
    required this.data,
    required this.nome,
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.camada,
    this.propriedades,
  });

  factory PontoModel.fromMap(Map<String, dynamic> map) {
    return PontoModel(
      id: map['id'] as int,
      missaoId: map['missao_id'] as int,
      numero: map['numero'] as int,
      data: DateTime.fromMillisecondsSinceEpoch(map['data_criacao'] as int),
      nome: map['nome'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      camada: map['camada'] as String?,
      propriedades: map['propriedades'] == null
          ? null
          : jsonDecode(map['propriedades'] as String) as Map<String, dynamic>,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'missao_id': missaoId,
      'numero': numero,
      'data_criacao': data.millisecondsSinceEpoch,
      'nome': nome,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'camada': camada,
      'propriedades': propriedades == null ? null : jsonEncode(propriedades),
    };
  }

  PontoModel copyWith({
    int? id,
    int? missaoId,
    int? numero,
    DateTime? data,
    String? nome,
    double? latitude,
    double? longitude,
    double? altitude,
    String? camada,
    Map<String, dynamic>? propriedades,
  }) {
    return PontoModel(
      id: id ?? this.id,
      missaoId: missaoId ?? this.missaoId,
      numero: numero ?? this.numero,
      data: data ?? this.data,
      nome: nome ?? this.nome,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      camada: camada ?? this.camada,
      propriedades: propriedades ?? this.propriedades,
    );
  }

  static Future<int> inserir(PontoModel ponto) async {
    final db = await Create.database;

    return await db.insert('pontos', ponto.toMap());
  }

  static Future<PontoModel?> buscarPorId(int id) async {
    final db = await Create.database;

    final resultado = await db.query(
      'pontos',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return PontoModel.fromMap(resultado.first);
  }

  static Future<List<PontoModel>> listarPorMissao(int missaoId) async {
    final db = await Create.database;

    final resultado = await db.query(
      'pontos',
      where: 'missao_id = ?',
      whereArgs: [missaoId],
      orderBy: 'numero ASC',
    );

    return resultado.map((map) => PontoModel.fromMap(map)).toList();
  }

  static Future<List<PontoModel>> listarPorMissaoComFotos(int missaoId) async {
    final db = await Create.database;
    final result = await db.rawQuery(
      '''
        SELECT DISTINCT p.*
        FROM pontos p
        INNER JOIN fotos f ON f.ponto_id = p.id
        WHERE p.missao_id = ?
        ORDER BY p.numero ASC
      ''',
      [missaoId],
    );
    return result.map((map) => PontoModel.fromMap(map)).toList();
  }

  static Future<int> obterProximoNumero(int missaoId) async {
    final db = await Create.database;

    final resultado = await db.rawQuery(
      '''
      SELECT COALESCE(MAX(numero), 0) + 1 AS proximo
      FROM pontos
      WHERE missao_id = ?
      ''',
      [missaoId],
    );

    return resultado.first['proximo'] as int;
  }

  static Future<String?> obterUltimoNome(int missaoId) async {
    final db = await Create.database;

    final r = await db.query(
      'pontos',
      columns: ['nome'],
      where: 'missao_id = ?',
      whereArgs: [missaoId],
      orderBy: 'numero DESC',
      limit: 1,
    );

    return r.isEmpty ? null : r.first['nome'] as String;
  }

  static Future<int> atualizar(PontoModel ponto) async {
    final db = await Create.database;

    return await db.update(
      'pontos',
      ponto.toMap(),
      where: 'id = ?',
      whereArgs: [ponto.id],
    );
  }

  static Future<int> excluirPonto(int id) async {
    final db = await Create.database;

    return await db.delete('pontos', where: 'id = ?', whereArgs: [id]);
  }

  static String sugerirProximoNome(String? ultimo) {
    final nome = ultimo?.trim() ?? '';
    if (nome.isEmpty) return 'A';

    // Se termina em número, incrementa o número
    final numero = RegExp(r'^(.*?)(\d+)$').firstMatch(nome);

    if (numero != null) {
      final digitos = numero.group(2)!;
      final proximo = (BigInt.parse(digitos) + BigInt.one).toString().padLeft(
        digitos.length,
        '0',
      );

      return '${numero.group(1)}$proximo';
    }

    // Se termina em letras, incrementa a sequência final
    final letras = RegExp(r'^(.*?)([A-Za-z]+)$').firstMatch(nome);

    if (letras != null) {
      final prefixo = letras.group(1)!;
      final sequencia = letras.group(2)!;
      final chars = sequencia.split('');

      for (var i = chars.length - 1; i >= 0; i--) {
        final c = chars[i];

        if (c != 'Z' && c != 'z') {
          chars[i] = String.fromCharCode(c.codeUnitAt(0) + 1);
          return '$prefixo${chars.join()}';
        }

        chars[i] = c == 'Z' ? 'A' : 'a';
      }

      final primeira = sequencia[0] == sequencia[0].toUpperCase() ? 'A' : 'a';

      return '$prefixo$primeira${chars.join()}';
    }

    // Nome livre: não tenta inventar uma sequência
    return '';
  }
}
