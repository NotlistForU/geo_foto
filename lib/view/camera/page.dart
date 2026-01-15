import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sipam_foto/view/camera/enum.dart';
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
    if (_tirandoFoto) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      setState(() => _tirandoFoto = true);
      final XFile xfile = await _controller!.takePicture();
      final File file = File(xfile.path);
      setState(() {
        _fotoAtual = file;
        _ultimaFoto = file;
      });
    } catch (e) {
      debugPrint('Erro ao tirar foto: $e');
    } finally {
      if (!mounted) {
        setState(() => _tirandoFoto = false);
      }
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
        return;
      }

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

  void _setState(CameraStatus novo) {
    if (!mounted) return;
    setState(() => _state = novo);
  }

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
    switch (_state) {
      case CameraStatus.loading:
        return _loading();
      case CameraStatus.semMissao:
        return _semMissao(context);
      case CameraStatus.permissaoNegada:
        return _permissaoNegada(context);
      case CameraStatus.inicializandoCamera:
        return _loading(texto: 'Inicializando câmera...');
      case CameraStatus.pronta:
        return _cameraPronta();
      case CameraStatus.erro:
        return _erroTela();
    }
  }

  Widget _loading({String texto = 'Carregando...'}) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(texto),
          ],
        ),
      ),
    );
  }

  Widget _semMissao(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Câmera')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.push(
              c,
              MaterialPageRoute(builder: (_) => const page.Missao()),
            );
            _setState(CameraStatus.loading);
            _initFluxo();
          },
          child: const Text('Ativar missão'),
        ),
      ),
    );
  }

  Widget _permissaoNegada(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Permissão necessária')),
      body: Center(
        child: ElevatedButton(
          onPressed: openAppSettings,
          child: const Text('Abrir configurações'),
        ),
      ),
    );
  }

  Widget _cameraPronta() {
    return Scaffold(
      appBar: AppBar(title: const Text('Câmera')),
      body: Stack(
        children: [
          Positioned.fill(
            bottom: height,
            child: widgets.Preview(
              imageFile: _fotoAtual,
              preview: CameraPreview(_controller!),
              dados: '',
              repaintKey: _repaintKey,
              lat: null,
              lng: null,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: widgets.BottomBar(
              ultimaFoto: _ultimaFoto,
              onFoto: _onFoto,
              onMaps: _onMaps,
              abrirMaps: _abrirMaps,
            ),
          ),
        ],
      ),
    );
  }

  Widget _erroTela() {
    return Scaffold(
      appBar: AppBar(title: const Text('Erro')),
      body: Center(child: Text(_erro ?? 'Erro desconhecido')),
    );
  }
}
