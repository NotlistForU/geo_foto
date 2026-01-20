import 'dart:async';
import 'dart:io' show Platform, File;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sipam_foto/database/localizacao/service.dart';

import 'package:sipam_foto/view/camera/enum.dart';

import 'package:http/http.dart' as http;

//IMPORT model
import 'package:sipam_foto/model/missao.dart' as model;
import 'package:sipam_foto/model/localizacao.dart' as model;

// IMPORT cases
import 'package:sipam_foto/view/camera/cases/loading.dart' as cases;
import 'package:sipam_foto/view/camera/cases/permissao_negada.dart' as cases;
import 'package:sipam_foto/view/camera/cases/sem_missao.dart' as cases;
import 'package:sipam_foto/view/camera/cases/camera_pronta.dart' as cases;
import 'package:sipam_foto/view/camera/cases/erro.dart' as cases;

// IMPORT widgets
import 'package:sipam_foto/view/camera/widget/preview.dart' as widgets;
import 'package:sipam_foto/view/camera/widget/bottom_bar.dart' as widgets;

import 'package:sipam_foto/view/camera/permissoes.dart' as permissao;
import 'package:sipam_foto/view/missao/missao.dart' as page;

// IMPORT database
import 'package:sipam_foto/database/missoes/update.dart' as update;
import 'package:sipam_foto/database/missoes/select.dart' as select;
import 'package:sipam_foto/database/fotos/insert.dart' as insert;

class Camera extends StatefulWidget {
  const Camera({super.key});
  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  CameraStatus _state = CameraStatus.loading;

  CameraController? _controller;
  List<CameraDescription>? _cameras;
  String? _erro;
  File? _ultimaFoto;
  File? _fotoTemporaria;
  File? _fotoAtual;
  final GlobalKey _repaintKey = GlobalKey();
  bool feedback = false;
  model.Localizacao? localizacaoAtual;

  late final StreamSubscription<model.Localizacao> sub;

  @override
  void initState() {
    super.initState();
    _initFluxo();
  }

  @override
  void dispose() {
    sub.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void onUpdate() {
    if (!mounted) return;
    setState(() {});
  }

  void triggerFeedback() {
    feedback = true;
    onUpdate();

    Future.delayed(const Duration(milliseconds: 120), () {
      feedback = false;
      onUpdate();
    });
  }

  // flag
  bool _tirandoFoto = false;
  void getTirandofoto() => _tirandoFoto;
  Future<void> _onFoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_tirandoFoto) return;
    try {
      setState(() {
        _tirandoFoto = true;
      });
      final XFile xfile = await _controller!.takePicture();
      final File file = File(xfile.path);
      setState(() {
        _fotoTemporaria = file;
        triggerFeedback();
      });
      await salvarFotoFinal();
      setState(() {
        _tirandoFoto = false;
      });
    } catch (e) {
      _erro = e.toString();
      _setState(CameraStatus.erro);
    }
  }

  Future<void> salvarFotoFinal() async {
    try {
      final missao = await select.Missao.missaoAtiva();
      if (missao == null) {
        throw Exception('Nenhuma missão ativa, foto não foi salva');
      }

      final boundary =
          _repaintKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final image = await boundary.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final permissao = await PhotoManager.requestPermissionExtend();
      if (!permissao.isAuth) {
        throw Exception('Permissão de galeria negada');
      }

      final albumNome = 'Sipam-${missao.nome}';
      final num = missao.contador + 1;
      final contadorAtual = num.toString().padLeft(2, '0');
      final arquivoNome = '${missao.nome}_$contadorAtual';

      final AssetEntity? asset = await PhotoManager.editor.saveImage(
        pngBytes,
        filename: '$arquivoNome.png',
        title: arquivoNome,
        relativePath: 'Pictures/$albumNome',
      );
      if (asset != null) {
        await insert.Insert.foto(
          missaoid: missao.id,
          nome: arquivoNome,
          asset_id: asset.id,
          latitude: localizacaoAtual?.latitude,
          longitude: localizacaoAtual?.longitude,
          altitude: localizacaoAtual?.altitude,
        );
        debugPrint('Foto salva no banco de dados');
      }
      debugPrint('Tirando foto = $_tirandoFoto');

      if (_fotoTemporaria != null && await _fotoTemporaria!.exists()) {
        await _fotoTemporaria!.delete();
        debugPrint('Foto temporaria deletada');
      }
      await update.Missao.contador();
      setState(() {
        _fotoTemporaria = null;
      });
    } catch (e) {
      _erro = e.toString();
      _setState(CameraStatus.erro);
    }
  }

  Future<bool> podeAbrirMaps() async {
    debugPrint(
      ">>> podeAbrirMaps chamado: localizacaoAtual = $localizacaoAtual",
    );
    try {
      localizacaoAtual != null;

      final tentativa = await http
          .get(Uri.parse("https://www.google.com"))
          .timeout(const Duration(seconds: 5));
      return tentativa.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _onMaps() async {
    if (await podeAbrirMaps()) {
      Uri url;
      if (Platform.isIOS) {
        url = Uri.parse(
          "geo:${localizacaoAtual!.latitude},${localizacaoAtual!.longitude}",
        );
      }
      if (Platform.isAndroid) {
        url = Uri.parse(
          "geo:${localizacaoAtual!.latitude},${localizacaoAtual!.longitude}?q=${localizacaoAtual!.latitude},${localizacaoAtual!.longitude}",
        );
      } else {
        url = Uri.parse(
          "https://maps.google.com/?q=${localizacaoAtual!.latitude},${localizacaoAtual!.longitude}",
        );
      }
      try {
        final launch = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        if (!launch) {
          debugPrint('>>>> nao conseguiu abrir o Map');
        }
      } catch (e, s) {
        debugPrint(">>> ERRO ao abrir Maps: $e");
        debugPrint(">>> Stacktrace: $s");
      }
    }
  }

  Future<void> _initFluxo() async {
    try {
      final missao = await select.Missao.missaoAtiva();
      if (missao == null) {
        _setState(CameraStatus.semMissao);
        debugPrint('sem missao ativa');
        return;
      }
      debugPrint('Missao ativa vmao ver a permissao');
      final permitido = await permissao.requestAllPermissions();
      if (!permitido) {
        _setState(CameraStatus.permissaoNegada);
        return;
      }

      _setState(CameraStatus.inicializandoCamera);
      await _initCamera();

      _setState(CameraStatus.pronta);
      sub = emTempoReal().listen((loc) {
        setState(() {
          localizacaoAtual = loc;
        });
      });
    } catch (e) {
      _erro = e.toString();
      _setState(CameraStatus.erro);
    }
  }

  void getInitFluxo() => _initFluxo();

  void _setState(CameraStatus novo) {
    if (!mounted) return;
    setState(() => _state = novo);
  }

  void getSetState(CameraStatus novo) => _setState(novo);

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      throw Exception('Nenhuma câmera disponível');
    }
    _controller = CameraController(
      _cameras!.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller!.initialize();
  }

  @override
  Widget build(BuildContext c) {
    debugPrint('>>> BUILD CAMERA PAGE <<<');
    switch (_state) {
      case CameraStatus.loading:
        return cases.loading();
      case CameraStatus.semMissao:
        return cases.SemMissao(
          onSetState: getSetState,
          onInitFluxo: getInitFluxo,
        );
      case CameraStatus.permissaoNegada:
        return cases.permissaoNegada(c);
      case CameraStatus.inicializandoCamera:
        return cases.loading(texto: 'Inicializando câmera...');
      case CameraStatus.pronta:
        return FutureBuilder<bool>(
          future: podeAbrirMaps(),
          builder: (context, snapshot) {
            final podeAbrir = snapshot.data ?? false;

            return cases.cameraPronta(
              tirandoFoto: _tirandoFoto,
              feedback: feedback,
              fotoTemporaria: _fotoTemporaria,
              controller: _controller!,
              repaintKey: _repaintKey,
              onFoto: _onFoto,
              onMaps: _onMaps,
              podeAbrirMaps: podeAbrir,
              localizacaoAtual: localizacaoAtual,
            );
          },
        );
      case CameraStatus.erro:
        return cases.erro(mensagem: _erro ?? 'Erro desconhecido');
    }
  }
}
