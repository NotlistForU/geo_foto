import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sipam_foto/model/foto_com_arquivo.dart';
import 'package:sipam_foto/model/localizacao.dart' as model;
import 'package:sipam_foto/model/foto.dart' as model;
import 'package:sipam_foto/model/foto_com_arquivo.dart' as model;
import 'package:sipam_foto/model/filtro.dart' as model;
import 'package:sipam_foto/database/missoes/select.dart' as select;
import 'package:sipam_foto/database/fotos/select.dart' as select;
import 'package:sipam_foto/database/fotos/insert.dart' as insert;
import 'package:sipam_foto/database/fotos/delete.dart' as delete;
import 'package:sipam_foto/database/fotos/update.dart' as update;

class FotoService {
  static Future<void> compartilharFotos(List<model.Foto> fotos) async {
    List<File?> arquivos = [];
    for (var foto in fotos) {
      arquivos.add(await FotoService.getFoto(foto));
    }
    List<XFile> array = [];
    for (final arquivo in arquivos) {
      if (arquivo == null) continue;
      array.add(XFile(arquivo.path));
    }
    final params = ShareParams(files: array);
    await SharePlus.instance.share(params);
  }

  static Future<Directory> getDiretorioMissao(int missaoId) async {
    final diretorioBase = await getExternalStorageDirectory();
    print('Base: ${diretorioBase?.path}');

    if (diretorioBase == null) {
      throw Exception('Não foi possível obter o diretório de armazenamento.');
    }

    final diretorioMissao = Directory('${diretorioBase.path}/Sipam-$missaoId');

    print('Missão: ${diretorioMissao.path}');

    if (!await diretorioMissao.exists()) {
      await diretorioMissao.create(recursive: true);
    }

    return diretorioMissao;
  }

  Future<void> salvarFoto({
    required Uint8List bytes,
    required int missaoId,
    model.Localizacao? localizacao,
  }) async {
    // busca missão
    final missao = await select.Missao.getMissaoById(missaoId);
    if (missao == null) {
      throw Exception('Missão não encontrada.');
    }
    // descobre o próximo numero
    final numero = await select.Foto.proximoNumeroSequencial(missaoId);

    // gerar o nome da foto
    final nomeArquivo = gerarNomeFoto(missao.nome, numero);

    // salvar arquivo físico
    final arquivo = await salvarArquivo(
      bytes: bytes,
      missaoId: missaoId,
      nomeArquivo: nomeArquivo,
    );

    try {
      // salvar no banco
      await insert.Foto.values(
        missaoId: missaoId,
        numero: numero,
        nome: nomeArquivo,
      );
    } catch (e) {
      if (await arquivo.exists()) {
        await arquivo.delete();
      }
      rethrow;
    }
  }

  Future<File> salvarArquivo({
    required Uint8List bytes,
    required int missaoId,
    required String nomeArquivo,
  }) async {
    final diretorio = await getDiretorioMissao(missaoId);
    final arquivo = File('${diretorio.path}/$nomeArquivo');

    await arquivo.writeAsBytes(bytes);

    return arquivo;
  }

  String gerarNomeFoto(String nomeMissao, int numero) {
    final nome = normalizarNomeMissao(nomeMissao);
    final numeroFormatado = numero.toString().padLeft(2, '0');

    return '$nome-$numeroFormatado.png';
  }

  String normalizarNomeMissao(String nomeMissao) {
    var nome = nomeMissao.toLowerCase();

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
      nome = nome.replaceAll(comAcento, semAcento);
    });

    nome = nome.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    nome = nome.replaceAll(RegExp(r'_+'), '_');
    nome = nome.replaceAll(RegExp(r'^_|_$'), '');

    return nome;
  }

  static Future<File?> getFoto(model.Foto foto) async {
    return getArquivo(missaoId: foto.missaoId, nomeArquivo: foto.nome);
  }

  static Future<File?> getArquivo({
    required int missaoId,
    required String nomeArquivo,
  }) async {
    final diretorio = await getDiretorioMissao(missaoId);
    final arquivo = File('${diretorio.path}/$nomeArquivo');

    if (await arquivo.exists()) {
      return arquivo;
    }
    return null;
  }

  Future<List<FotoComArquivo>> listarFotos(model.Filtro filtro) async {
    final fotos = await select.Foto.filtro(filtro);
    final List<model.FotoComArquivo> resultado = [];

    for (final foto in fotos) {
      final arquivo = await getFoto(foto);

      if (arquivo != null) {
        resultado.add(model.FotoComArquivo(foto: foto, arquivo: arquivo));
      } else {
        await delete.Foto.uma(foto);
      }
    }
    return resultado;
  }

  Future<void> renumerarTodasMissoes() async {
    final missoes = await select.Missao.todasMissoes();
    for (final missao in missoes) {
      await renumerarFotos(missao.id);
    }
  }

  Future<void> renumerarFotos(int missaoId) async {
    final missao = await select.Missao.getMissaoById(missaoId);
    if (missao == null) return;

    final fotos = await select.Foto.porIdMissao(missaoId);
    final diretorio = await getDiretorioMissao(missaoId);

    for (var i = 0; i < fotos.length; i++) {
      final foto = fotos[i];
      final novoNumero = i + 1;

      if (foto.numero == novoNumero) continue;

      final novoNome = gerarNomeFoto(missao.nome, novoNumero);
      final antigoArquivo = File('${diretorio.path}/${foto.nome}');
      final novoArquivo = File('${diretorio.path}/$novoNome');

      if (await antigoArquivo.exists()) {
        await antigoArquivo.rename(novoArquivo.path);
      }

      await update.Foto.numeroEnome(
        id: foto.id,
        numero: novoNumero,
        nome: novoNome,
      );
    }
  }
}

// Future<void> excluirFoto(...)

// Future<void> renumerar(...)
