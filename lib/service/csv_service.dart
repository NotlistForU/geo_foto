import 'dart:convert';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sipam_foto/model/foto_model.dart';
import 'package:sipam_foto/model/missao_model.dart';

class CsvService {
  final FormatoCsv formato;

  //sem ele o Excel abre UTF-8 com os acentos quebrados
  final StringBuffer _buf = StringBuffer('\uFEFF');

  CsvService(this.formato);

  /// Número com o decimal do formato; null vira célula vazia.
  String numero(double? v, {int casas = 6}) {
    if (v == null) return '';
    return v.toStringAsFixed(casas).replaceAll('.', formato.decimal);
  }

  /// Texto com aspas quando precisa.
  String texto(Object? v) {
    var s = v?.toString() ?? '';

    // Evita que o Excel execute o texto como fórmula (=, +, -, @)
    if (s.isNotEmpty && '=+-@'.contains(s[0])) s = "'$s";

    final precisaAspas =
        s.contains(formato.separador) ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r');

    return precisaAspas ? '"${s.replaceAll('"', '""')}"' : s;
  }

  /// Recebe as células já formatadas (por texto() ou numero()).
  void linha(List<String> celulas) {
    _buf.write('${celulas.join(formato.separador)}\r\n');
  }

  String get conteudo => _buf.toString();

  static Future<void> compartilharMissaoCsv({
    required MissaoModel missao,
    required List<FotoModel> fotos,
    FormatoCsv formato = FormatoCsv.brasil,
  }) async {
    final file = await criarMissaoCsv(
      missao: missao,
      fotos: fotos,
      formato: formato,
    );

    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'Missão ${missao.nome}',
        text: 'Exportação da missão ${missao.nome}',
      ),
    );
  }

  static Future<File> criarMissaoCsv({
    required MissaoModel missao,
    required List<FotoModel> fotos,
    FormatoCsv formato = FormatoCsv.brasil,
  }) async {
    final csv = CsvService(formato);
    final dataFmt = DateFormat('dd/MM/yyyy HH:mm:ss');

    csv.linha(
      [
        'Missão',
        'Nome da Foto',
        'Latitude',
        'Longitude',
        'Altitude (m)',
        'Data/Hora',
        'Observações',
      ].map(csv.texto).toList(),
    );

    for (final foto in fotos) {
      csv.linha([
        csv.texto(missao.nome),
        csv.texto(foto.nome),
        csv.numero(foto.latitude),
        csv.numero(foto.longitude),
        csv.numero(foto.altitude),
        csv.texto(dataFmt.format(foto.data)),
        csv.texto(foto.observacoes),
      ]);
    }
    final dir = await getTemporaryDirectory();
    final nomeSeguro = missao.nome.replaceAll(RegExp(r'[^\w\-]+'), '_');
    final file = File('${dir.path}/missao_$nomeSeguro.csv');
    return file.writeAsString(csv.conteudo, encoding: utf8, flush: true);
  }
}

enum FormatoCsv {
  brasil(separador: ';', decimal: ','),
  internacional(separador: ',', decimal: '.');

  final String separador;
  final String decimal;
  const FormatoCsv({required this.separador, required this.decimal});
}
