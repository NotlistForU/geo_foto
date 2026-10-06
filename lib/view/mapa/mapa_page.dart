import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
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
  late final Future<List<MapOverlay>> _overlays = MapOverlay.loadAll();
  MissaoModel? missao;
  List<PontoModel> _pontos = [];
  bool _criando = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final resultado = await MissaoModel.buscarAtiva();
    if (!mounted) return;
    if (resultado == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      missao = resultado;
    });

    if (missao != null) {
      await _carregarPontos();
    }
  }

  Future<void> _carregarPontos() async {
    final pontos = await PontoModel.listarPorMissao(missao!.id);
    if (!mounted) return;
    setState(() => _pontos = pontos);
  }

  Future<void> _criarPonto() async {
    if (_criando) return;
    setState(() => _criando = true);

    try {
      final pos = await LocalizacaoService.posicaoAtual();
      final numero = await PontoModel.obterProximoNumero(missao!.id);

      final novo = PontoModel(
        id: 0, // ignorado no insert (toMap não envia id)
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao criar ponto: $e')));
    } finally {
      if (mounted) setState(() => _criando = false);
    }
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

  Marker _marcador(PontoModel ponto) {
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
                color: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa')),
      floatingActionButton: FloatingActionButton.extended(
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
      body: FutureBuilder<List<MapOverlay>>(
        future: _overlays,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar mapas: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(-7.6393, -72.6628),
              initialZoom: 12,
            ),
            children: [
              // 1) mapa base
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.sipam_foto',
              ),
              // 2) PNG por cima do mapa
              OverlayImageLayer(
                overlayImages: [
                  for (final o in snapshot.data!)
                    OverlayImage(
                      imageProvider: AssetImage(o.imageAsset),
                      bounds: o.bounds,
                    ),
                ],
              ),
              // 3) pontos por cima do PNG
              MarkerLayer(markers: [for (final p in _pontos) _marcador(p)]),
            ],
          );
        },
      ),
    );
  }
}
