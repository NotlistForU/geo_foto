import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sipam_foto/database/localizacao/service.dart';

import 'package:sipam_foto/view/camera/enum.dart';

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
  bool _abrirMaps = false;
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

  Future<void> _onFoto() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) return;
      final XFile xfile = await _controller!.takePicture();
      final File file = File(xfile.path);
      setState(() {
        _fotoTemporaria = file;
        triggerFeedback();
      });
      await salvarFotoFinal();
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

      await PhotoManager.editor.saveImage(
        pngBytes,
        filename: '$arquivoNome.png',
        title: arquivoNome,
        relativePath: 'Pictures/$albumNome',
      );

      if (_fotoTemporaria != null && await _fotoTemporaria!.exists()) {
        await _fotoTemporaria!.delete();
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

  void _onMaps() {
    debugPrint('Abrir maps');
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
        return cases.cameraPronta(
          feedback: feedback,
          fotoTemporaria: _fotoTemporaria,
          controller: _controller!,
          repaintKey: _repaintKey,
          onFoto: _onFoto,
          onMaps: _onMaps,
          abrirMaps: _abrirMaps,
          localizacaoAtual: localizacaoAtual,
        );
      case CameraStatus.erro:
        return cases.erro(mensagem: _erro ?? 'Erro desconhecido');
    }
  }
}
