import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class Create {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) {
      return _db!;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE missoes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data_criacao INTEGER NOT NULL,
            nome TEXT NOT NULL UNIQUE,
            ativa INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE mapas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            missao_id INTEGER NOT NULL UNIQUE,
            image_path TEXT NOT NULL,
            south REAL NOT NULL,
            north REAL NOT NULL,
            west REAL NOT NULL,
            east REAL NOT NULL,
            FOREIGN KEY (missao_id)
              REFERENCES missoes(id)
              ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE pontos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            missao_id INTEGER NOT NULL,
            numero INTEGER NOT NULL,
            data_criacao INTEGER NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            altitude REAL NOT NULL,

            UNIQUE (missao_id, numero),

            FOREIGN KEY (missao_id)
              REFERENCES missoes(id)
              ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE fotos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ponto_id INTEGER NOT NULL,
            numero INTEGER NOT NULL,
            data_criacao INTEGER NOT NULL,
            nome TEXT NOT NULL,
            latitude REAL,
            longitude REAL,
            altitude REAL,

            UNIQUE (ponto_id, numero),

            FOREIGN KEY (ponto_id)
              REFERENCES pontos(id)
              ON DELETE CASCADE
          )
        ''');
      },
    );

    return _db!;
  }
}
