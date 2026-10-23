import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipam_foto/model/missao_model.dart';
import 'package:sipam_foto/model/ponto_model.dart';
import 'package:sipam_foto/service/importar_mapa_service.dart';
import 'package:sipam_foto/service/localizacao_service.dart';
import 'package:sipam_foto/view/ponto_widget.dart';
import 'dart:io';
import 'package:sipam_foto/model/mapa_model.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final MapController _mapController = MapController();

  MissaoModel? missao;
  MapaModel? _mapa;
  List<PontoModel> _pontos = [];

  LatLng? _minhaPosicao;
  Position? _ultimaPosicao;
  double? _precisao;
  StreamSubscription<Position>? _posSub;
  bool _centralizouInicial = false;
  bool _criando = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final resultado = await MissaoModel.buscarAtiva();
    if (!mounted) return;
    // TODO: retornar com uma mensagem de erro (ative uma missao antes!)
    if (resultado == null) {
      Navigator.pop(context);
      return;
    }
    setState(() => missao = resultado);
    await _carregarPontos();
    await _carregarMapa();
  }

  // PNG é opcional: se não existir ou falhar, o mapa segue normal.
  Future<void> _carregarMapa() async {
    try {
      final mapa = await MapaModel.buscarPorMissao(missao!.id);
      if (mapa != null && !await File(mapa.imagePath).exists()) {
        _aviso('Arquivo do mapa não encontrado');
        return;
      }
      if (!mounted) return;
      setState(() => _mapa = mapa);
    } catch (e) {
      _aviso('Erro ao carregar mapa: $e');
    }
  }

  void _abrirPonto(PontoModel ponto) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => PontoWidget(
        ponto: ponto,
        onCameraAberta: _pausarLocalizacao,
        onCameraFechada: _retomarLocalizacao,
      ),
    );
  }

  Future<void> _carregarPontos() async {
    try {
      final pontos = await PontoModel.listarPorMissao(missao!.id);
      if (!mounted) return;
      setState(() => _pontos = pontos);
    } catch (e) {
      _aviso('Erro ao carregar pontos: $e');
    }
  }

  void _iniciarStream() {
    _posSub?.cancel();
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(_atualizarPosicao);
  }

  Future<void> _iniciarLocalizacao() async {
    try {
      final inicial = await LocalizacaoService.posicaoAtual();
      _atualizarPosicao(inicial);
      _iniciarStream();
    } catch (e) {
      _aviso('Localização indisponível: $e');
    }
  }

  void _pausarLocalizacao() {
    _posSub?.cancel();
    _posSub = null;
  }

  void _retomarLocalizacao() {
    if (!mounted) return;
    _iniciarStream();
  }

  void _atualizarPosicao(Position p) {
    if (!mounted) return;
    final pos = LatLng(p.latitude, p.longitude);
    setState(() {
      _ultimaPosicao = p;
      _minhaPosicao = pos;
      _precisao = p.accuracy;
    });

    if (!_centralizouInicial) {
      _centralizouInicial = true;
      _mapController.move(pos, 18);
    }
  }

  void _centralizarEmMim() {
    final pos = _minhaPosicao;
    if (pos == null) {
      _aviso('Ainda sem localização');
      return;
    }
    _mapController.move(pos, 18);
  }

  Future<void> _criarPonto() async {
    if (_criando || missao == null) return;
    setState(() => _criando = true);

    try {
      final pos = _ultimaPosicao ?? await LocalizacaoService.posicaoAtual();
      final numero = await PontoModel.obterProximoNumero(missao!.id);

      if (!mounted) return;

      final nome = await showDialog<String>(
        context: context,
        builder: (context) {
          String nomePonto = 'ponto${numero.toString().padLeft(2, '0')}';

          return AlertDialog(
            title: const Text('Nome do ponto'),
            content: TextFormField(
              initialValue: nomePonto,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome'),
              onChanged: (value) {
                nomePonto = value;
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  final texto = nomePonto.trim();

                  if (texto.isNotEmpty) {
                    Navigator.pop(context, texto);
                  }
                },
                child: const Text('Criar'),
              ),
            ],
          );
        },
      );

      if (nome == null) {
        return;
      }

      final novo = PontoModel(
        id: 0,
        missaoId: missao!.id,
        numero: numero,
        data: DateTime.now(),
        nome: nome,
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: pos.altitude,
      );

      await PontoModel.inserir(novo);
      await _carregarPontos();

      _mapController.move(LatLng(pos.latitude, pos.longitude), 18);

      _aviso('Ponto criado (precisão ±${pos.accuracy.toStringAsFixed(0)} m)');
    } catch (e) {
      _aviso('Erro ao criar ponto: $e');
    } finally {
      if (mounted) setState(() => _criando = false);
    }
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Marker _marcadorPonto(PontoModel ponto) {
    return Marker(
      point: LatLng(ponto.latitude, ponto.longitude),
      width: 200,
      height: 56,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _abrirPonto(ponto),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IntrinsicWidth(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  '${ponto.nome}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Icon(Icons.location_on, color: Colors.red, size: 32),
          ],
        ),
      ),
    );
  }

  Marker _marcadorUsuario(LatLng pos) {
    return Marker(
      point: pos,
      width: 24,
      height: 24,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black38)],
        ),
      ),
    );
  }

  void _irParaMapa() {
    final m = _mapa;
    if (m == null) {
      _aviso('Esta missão não tem mapa carregado');
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: [m.upperLeft, m.upperRight, m.lowerRight, m.lowerLeft],
        padding: const EdgeInsets.all(24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'ir_mapa',
            onPressed: _irParaMapa,
            child: const Icon(Icons.map),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'minha_posicao',
            onPressed: _centralizarEmMim,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'criar_ponto',
            onPressed: _criando ? null : _criarPonto,
            icon: _criando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_location_alt),
            label: const Text('Criar ponto'),
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: LatLng(
            -3.46,
            -62.22,
          ), // lat long do Centro da Floresta Amazônica.
          initialZoom: 6,
          onMapReady: _iniciarLocalizacao,
        ),
        children: [
          // 1) mapa base
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.sipam_foto',
          ),
          // 2) PNG (só entra se existir)
          if (_mapa != null)
            OverlayImageLayer(
              overlayImages: [
                RotatedOverlayImage(
                  imageProvider: FileImage(File(_mapa!.imagePath)),
                  topLeftCorner: _mapa!.upperLeft,
                  bottomLeftCorner: _mapa!.lowerLeft,
                  bottomRightCorner: _mapa!.lowerRight,
                ),
              ],
            ),
          // 3) círculo de precisão do GPS
          if (_minhaPosicao != null && _precisao != null)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _minhaPosicao!,
                  radius: _precisao!,
                  useRadiusInMeter: true,
                  color: Colors.blue.withOpacity(0.15),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 1,
                ),
              ],
            ),
          // 4) pontos
          MarkerLayer(markers: [for (final p in _pontos) _marcadorPonto(p)]),
          // 5) bolinha azul do usuário (por cima de tudo)
          if (_minhaPosicao != null)
            MarkerLayer(markers: [_marcadorUsuario(_minhaPosicao!)]),
        ],
      ),
    );
  }
}
