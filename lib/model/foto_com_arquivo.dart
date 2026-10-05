import 'dart:io';

import 'package:sipam_foto/model/foto.dart' as model;

class FotoComArquivo {
  final model.Foto foto;
  final File arquivo;

  FotoComArquivo({required this.foto, required this.arquivo});
}
