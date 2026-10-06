import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:sipam_foto/model/missao_model.dart';
import 'package:sipam_foto/model/ponto_model.dart';
import 'package:sipam_foto/service/localizacao_service.dart';
import 'package:sipam_foto/view/mapa/mapa_overlay.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final MapController _mapController = MapController();

  MissaoModel? missao;
  List<MapOverlay> _overlays = [];
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
    _carregarOverlays();
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
  }

  // PNG é opcional: se não existir ou falhar, o mapa segue normal.
  Future<void> _carregarOverlays() async {
    try {
      final overlays = await MapOverlay.loadAll();
      if (!mounted) return;
      setState(() => _overlays = overlays);
    } catch (_) {
      // sem PNG, sem problema
    }
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

  // Chamado quando o mapa fica pronto (aí o MapController já pode mover).
  Future<void> _iniciarLocalizacao() async {
    try {
      final inicial = await LocalizacaoService.posicaoAtual(); // pede permissão
      _atualizarPosicao(inicial);

      _posSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen(_atualizarPosicao);
    } catch (e) {
      _aviso('Localização indisponível: $e');
    }
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

      final novo = PontoModel(
        id: 0,
        missaoId: missao!.id,
        numero: numero,
        data: DateTime.now(),
        nome: 'Ponto ${numero.toString().padLeft(2, '0')}',
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

  void _abrirPonto(PontoModel ponto) {
    // Passo 4: bottom sheet com as fotos + botão de tirar foto
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(ponto.nome, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '${ponto.latitude.toStringAsFixed(6)}, '
                '${ponto.longitude.toStringAsFixed(6)}',
              ),
              // TODO passo 4: grid de fotos + botão "Tirar foto"
            ],
          ),
        ),
      ),
    );
  }

  Marker _marcadorPonto(PontoModel ponto) {
    return Marker(
      point: LatLng(ponto.latitude, ponto.longitude),
      width: 48,
      height: 56,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () => _abrirPonto(ponto),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                '${ponto.numero}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
          initialCenter: LatLng(-7.6393, -72.6628),
          initialZoom: 12,
          onMapReady: _iniciarLocalizacao,
        ),
        children: [
          // 1) mapa base
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.sipam_foto',
          ),
          // 2) PNG (só entra se existir)
          if (_overlays.isNotEmpty)
            OverlayImageLayer(
              overlayImages: [
                for (final o in _overlays)
                  OverlayImage(
                    imageProvider: AssetImage(o.imageAsset),
                    bounds: o.bounds,
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
