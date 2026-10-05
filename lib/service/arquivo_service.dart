import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

class ArquivoService {
  //======================== BASE/ ================================================
  static Future<Directory> _diretorioBase() async {
    final diretorio = await getExternalStorageDirectory();

    if (diretorio == null) {
      throw Exception('Não foi possível obter o diretório de armazenamento.');
    }

    return diretorio;
  }

  //========================== CRIAR =================================================
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

  //=========================== SALVAR ==================================================
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

  static Future<File> salvarFoto({
    required String nomeMissao,
    required String nomePonto,
    required int numero,
    required Uint8List bytes,
  }) async {
    final diretorio = await criarDiretorioPonto(
      nomeMissao: nomeMissao,
      nomePonto: nomePonto,
    );

    final missao = normalizarNome(nomeMissao);
    final ponto = normalizarNome(nomePonto);
    final numeroFormatado = numero.toString().padLeft(2, '0');

    final nomeArquivo = '${missao}_${ponto}_foto$numeroFormatado.png';

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
