import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:sipam_foto/database/create.dart';
import 'package:sipam_foto/model/mapa_model.dart';
import 'package:sipam_foto/model/missao_model.dart';
import 'package:sipam_foto/model/ponto_model.dart';
import 'package:sipam_foto/model/foto_model.dart';
import 'package:share_plus/share_plus.dart';

class ArquivoService {
  //================ COMPARTILHAR ARQUIVOS =========================================
  static Future<void> compartilharFotos(List<FotoModel> fotos) async {
    if (fotos.isEmpty) {
      throw Exception('A missão não possui fotos.');
    }

    final arquivos = <XFile>[];

    for (final foto in fotos) {
      final arquivo = await getFoto(foto);

      if (arquivo != null && await arquivo.exists()) {
        arquivos.add(XFile(arquivo.path));
      }
    }

    if (arquivos.isEmpty) {
      throw Exception('Nenhuma foto encontrada no armazenamento.');
    }

    ShareParams shareParams = ShareParams(files: arquivos);

    await SharePlus.instance.share(shareParams);
  }

  //================ CRIAR MODEL + DIRETORIOS =======================================
  static Future<MissaoModel> criarMissao({
    required String nomeMissao,
    required bool ativar,
  }) async {
    final missao = MissaoModel(
      id: 0,
      data: DateTime.now(),
      nome: nomeMissao,
      ativa: ativar,
    );

    final id = await MissaoModel.inserir(missao);

    final resultado = missao.copyWith(id: id);

    await criarDiretorioMissao(nomeMissao: resultado.nome);

    return resultado;
  }

  static Future<PontoModel> criarPonto({
    required int missaoId,
    required String nome,
    required double latitude,
    required double longitude,
    required double altitude,
  }) async {
    final missao = await MissaoModel.buscarPorId(missaoId);

    if (missao == null) {
      throw Exception('Missão não encontrada.');
    }

    final numero = await PontoModel.obterProximoNumero(missaoId);

    final ponto = PontoModel(
      id: 0,
      missaoId: missaoId,
      numero: numero,
      data: DateTime.now(),
      nome: nome,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
    );

    final id = await PontoModel.inserir(ponto);

    final resultado = ponto.copyWith(id: id);

    await criarDiretorioPonto(nomeMissao: missao.nome, ponto: resultado);

    return resultado;
  }

  //========================== SALVAR MODEL + ARQUIVO ==============================
  static Future<FotoModel> salvarFoto({
    required int pontoId,
    required Uint8List bytes,
    double? latitude,
    double? longitude,
    double? altitude,
    String? observacoes,
    DateTime? data,
  }) async {
    final ponto = await PontoModel.buscarPorId(pontoId);

    if (ponto == null) {
      throw Exception('Ponto não encontrado.');
    }

    final missao = await MissaoModel.buscarPorId(ponto.missaoId);

    if (missao == null) {
      throw Exception('Missão não encontrada.');
    }

    final numero = await FotoModel.obterProximoNumero(pontoId);

    print("Nome do ponto: " + ponto.nome);

    final nomeArquivo =
        '${normalizarNome(missao.nome, lowerCase: false)}'
        '_${normalizarNome(ponto.nome, lowerCase: false)}'
        '_${numero.toString().padLeft(2, '0')}.png';

    print("Nome da foto: " + nomeArquivo);

    final arquivo = await salvarFotoArquivo(
      nomeMissao: missao.nome,
      ponto: ponto,
      nomeArquivo: nomeArquivo,
      bytes: bytes,
    );

    try {
      final foto = FotoModel(
        id: 0,
        data: data ?? DateTime.now(),
        pontoId: pontoId,
        numero: numero,
        nome: nomeArquivo,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        observacoes: observacoes,
      );

      final id = await FotoModel.inserir(foto);

      return foto.copyWith(id: id);
    } catch (e) {
      if (await arquivo.exists()) {
        await arquivo.delete();
      }

      rethrow;
    }
  }

  //============================= EXCLUIR MODEL + ARQUIVO =========================
  static Future<void> excluirFoto(FotoModel foto) async {
    await excluirFotos([foto]);
  }

  static Future<void> excluirFotos(List<FotoModel> fotos) async {
    final excluidas = <FotoModel>[];

    try {
      // 1. Remove do banco
      for (final foto in fotos) {
        await FotoModel.excluir(foto.id);
        excluidas.add(foto);
      }

      // 2. Remove os arquivos
      for (final foto in fotos) {
        await excluirFotoArquivo(foto);
      }
    } catch (e) {
      // 3. Rollback do banco
      for (final foto in excluidas) {
        try {
          await FotoModel.inserir(foto);
        } catch (erroRollback) {
          throw Exception(
            'Erro ao excluir as fotos e restaurar o banco: $erroRollback',
          );
        }
      }

      rethrow;
    }
  }

  //======================== SALVAR ARQUIVO =======================================
  static Future<File> salvarFotoArquivo({
    required Uint8List bytes,
    required String nomeMissao,
    required PontoModel ponto,
    required String nomeArquivo,
  }) async {
    final diretorio = await criarDiretorioPonto(
      nomeMissao: nomeMissao,
      ponto: ponto,
    );
    final arquivo = File('${diretorio.path}/$nomeArquivo');
    await arquivo.writeAsBytes(bytes);

    return arquivo;
  }

  //======================== BASE/ ================================================
  static Future<Directory> _diretorioBase() async {
    final diretorio = await getExternalStorageDirectory();

    if (diretorio == null) {
      throw Exception('Não foi possível obter o diretório de armazenamento.');
    }

    return diretorio;
  }

  //======================= CRIAR DIRETORIOS =======================================
  static Future<Directory> criarDiretorioMissao({
    required String nomeMissao,
  }) async {
    final base = await _diretorioBase();
    final nome = normalizarNome(nomeMissao);

    final diretorio = Directory('${base.path}/$nome');

    await diretorio.create(recursive: true);

    return diretorio;
  }

  static Future<Directory> criarDiretorioPontos({
    required String nomeMissao,
  }) async {
    final diretorioMissao = await criarDiretorioMissao(nomeMissao: nomeMissao);

    final diretorio = Directory('${diretorioMissao.path}/pontos');

    await diretorio.create(recursive: true);

    return diretorio;
  }

  /// - Se ja existir retorna o diretorio
  static Future<Directory> criarDiretorioPonto({
    required String nomeMissao,
    required PontoModel ponto,
  }) async {
    final diretorioPontos = await criarDiretorioPontos(nomeMissao: nomeMissao);

    final diretorio = Directory(
      '${diretorioPontos.path}/${nomeDaPastaPonto(ponto)}',
    );

    await diretorio.create(recursive: true);

    return diretorio;
  }

  //=========================== SALVAR ARQUIVO ==================================================
  static Future<File> salvarMapa({
    required String nomeMissao,
    required Uint8List bytes,
    required String nomeArquivo,
  }) async {
    final diretorio = await criarDiretorioMissao(nomeMissao: nomeMissao);

    final arquivo = File('${diretorio.path}/$nomeArquivo');

    await arquivo.writeAsBytes(bytes);

    return arquivo;
  }

  //============================= EXCLUIR (ENUM no final do arquivo) =====================================
  static Future<ResultadoExclusao> excluirMissao(MissaoModel missao) async {
    final db = await Create.database;

    // Guarda o mapa antes: o PNG fica em docs/mapas, fora da pasta da missão
    final mapa = await MapaModel.buscarPorMissao(missao.id);

    // 1. Banco (o cascade leva mapas, pontos e fotos junto)
    await db.delete('missoes', where: 'id = ?', whereArgs: [missao.id]);

    // 2. Arquivos: falha aqui não desfaz a exclusão
    try {
      await excluirPastaMissao(missao);

      if (mapa != null) {
        final png = File(mapa.imagePath);
        if (await png.exists()) await png.delete();
      }
      return ResultadoExclusao.completa;
    } catch (e) {
      return ResultadoExclusao.arquivosPendentes;
    }
  }

  static Future<void> excluirPastaMissao(MissaoModel missao) async {
    final dir = await getDiretorioMissao(missao);
    if (dir == null) return;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  static Future<void> excluirPastaPontos(MissaoModel missao) async {
    final base = await getDiretorioMissao(missao);
    if (base == null) return;

    final dir = Directory('${base.path}/pontos');
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static Future<void> excluirFotoArquivo(FotoModel foto) async {
    final arquivo = await getFoto(foto);

    if (arquivo == null) {
      return;
    }

    if (await arquivo.exists()) {
      await arquivo.delete();
    }
  }

  //============================ GET's ================================================
  static Future<File?> getFoto(FotoModel foto) async {
    final ponto = await PontoModel.buscarPorId(foto.pontoId);

    if (ponto == null) {
      return null;
    }

    final missao = await MissaoModel.buscarPorId(ponto.missaoId);

    if (missao == null) {
      return null;
    }

    final diretorio = await getDiretorioPonto(ponto);

    if (diretorio == null) {
      return null;
    }

    final arquivo = File('${diretorio.path}/${foto.nome}');

    if (await arquivo.exists()) {
      return arquivo;
    }

    return null;
  }

  static Future<List<File?>> getFotos(List<FotoModel> fotos) async {
    List<File> arquivos = [];
    for (final foto in fotos) {
      final arquivo = await getFoto(foto);

      if (arquivo == null) continue;
      arquivos.add(arquivo);
    }
    return arquivos;
  }

  static Future<Directory?> getDiretorioPonto(PontoModel ponto) async {
    final missao = await MissaoModel.buscarPorId(ponto.missaoId);

    if (missao == null) {
      return null;
    }

    final diretorioBase = await getDiretorioMissao(missao);

    if (diretorioBase == null) {
      return null;
    }

    return Directory('${diretorioBase.path}/pontos/${nomeDaPastaPonto(ponto)}');
  }

  static Future<Directory?> getDiretorioMissao(MissaoModel missao) async {
    final base = await _diretorioBase();

    return Directory('${base.path}/${normalizarNome(missao.nome)}');
  }

  //============================ UTIL =================================================
  static String normalizarNome(String nome, {bool lowerCase = true}) {
    var result = nome;
    if (lowerCase) {
      result = nome.toLowerCase();
    }

    const acentos = {
      'á': 'a',
      'à': 'a',
      'ã': 'a',
      'â': 'a',
      'ä': 'a',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ó': 'o',
      'ò': 'o',
      'õ': 'o',
      'ô': 'o',
      'ö': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
    };

    acentos.forEach((comAcento, semAcento) {
      result = result.replaceAll(comAcento, semAcento);
    });

    result = result.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_|_$'), '');

    return result;
  }

  static String nomeDaPastaPonto(PontoModel ponto) {
    return "ponto_${ponto.numero.toString().padLeft(3, '0')}";
  }
}

enum ResultadoExclusao { completa, arquivosPendentes }
