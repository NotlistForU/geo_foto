import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import 'package:sipam_foto/view/camera/enum.dart';
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
  bool _tirandoFoto = false;

  static const double height = widgets.BottomBar.height;

  @override
  void initState() {
    super.initState();
    _initFluxo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onFoto() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) return;
      final XFile xfile = await _controller!.takePicture();
      final File file = File(xfile.path);
      setState(() {
        _fotoTemporaria = file;
      });
    } catch (e) {
      _erro = e.toString();
      _setState(CameraStatus.erro);
    }
  }

  Future<void> salvarFotoFinal() async {
    try {
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
      final missao = select.Missao.missaoAtiva();
      // final AssetPathEntity albumSipam = await _getOrCreateAlbum('SIPAM');
      // final AssetPathEntity subAlbum = await _getOrCreateAlbum(
      //   '${missao.}'
      // )

      final dir = Directory('/storage/emulated/0/Picures/missao/missao_01');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final fileName = 'foto_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pngBytes);

      if (_fotoTemporaria != null && await _fotoTemporaria!.exists()) {
        await _fotoTemporaria!.delete();
      }
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
      final permitido = await permissao.requestCameraAndLocationPermissions();
      if (!permitido) {
        _setState(CameraStatus.permissaoNegada);
        return;
      }

      _setState(CameraStatus.inicializandoCamera);
      await _initCamera();

      _setState(CameraStatus.pronta);
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
          fotoTemporaria: _fotoTemporaria,
          controller: _controller!,
          repaintKey: _repaintKey,
          onFoto: _onFoto,
          onMaps: _onMaps,
          abrirMaps: _abrirMaps,
        );
      case CameraStatus.erro:
        return cases.erro(mensagem: _erro ?? 'Erro desconhecido');
    }
  }
}
