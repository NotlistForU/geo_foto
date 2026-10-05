import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:sipam_foto/model/missao_model.dart';
import 'package:sipam_foto/model/ponto_model.dart';
import 'package:sipam_foto/model/foto_model.dart';

class ArquivoService {
  //================ CRIAR MODEL + DIRETORIOS =======================================
  static Future<MissaoModel> criarMissao({required String nome}) async {
    final missao = MissaoModel(
      id: 0,
      data: DateTime.now(),
      nome: nome,
      ativa: true,
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

    await criarDiretorioPonto(
      nomeMissao: missao.nome,
      nomePonto: resultado.nome,
    );

    return resultado;
  }

  //========================== SALVAR MODEL + ARQUIVO ==============================
  static Future<FotoModel> salvarFoto({
    required int pontoId,
    required Uint8List bytes,
    double? latitude,
    double? longitude,
    double? altitude,
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

    final nomeArquivo =
        '${normalizarNome(missao.nome)}'
        '_${normalizarNome(ponto.nome)}'
        '_foto${numero.toString().padLeft(2, '0')}.png';

    final arquivo = await salvarFotoArquivo(
      nomeMissao: missao.nome,
      nomePonto: ponto.nome,
      nomeArquivo: nomeArquivo,
      bytes: bytes,
    );

    try {
      final foto = FotoModel(
        id: 0,
        data: DateTime.now(),
        pontoId: pontoId,
        numero: numero,
        nome: nomeArquivo,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
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

  //======================== SALVAR ARQUIVO =======================================
  static Future<File> salvarFotoArquivo({
    required Uint8List bytes,
    required String nomeMissao,
    required String nomePonto,
    required String nomeArquivo,
  }) async {
    final diretorio = await criarDiretorioPonto(
      nomeMissao: nomeMissao,
      nomePonto: nomePonto,
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

  static Future<Directory> criarDiretorioPonto({
    required String nomeMissao,
    required String nomePonto,
  }) async {
    final diretorioPontos = await criarDiretorioPontos(nomeMissao: nomeMissao);

    final nome = normalizarNome(nomePonto);

    final diretorio = Directory('${diretorioPontos.path}/$nome');

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

  //============================ UTIL =================================================
  static String normalizarNome(String nome) {
    var resultado = nome.toLowerCase();

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
      resultado = resultado.replaceAll(comAcento, semAcento);
    });

    resultado = resultado.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    resultado = resultado.replaceAll(RegExp(r'_+'), '_');
    resultado = resultado.replaceAll(RegExp(r'^_|_$'), '');

    return resultado;
  }
}
