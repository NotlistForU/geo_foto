import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:camera_overlay/camera_overlay.dart' as cam;
import 'package:sipam_foto/model/foto_model.dart';
import 'package:sipam_foto/model/ponto_model.dart';
import 'package:sipam_foto/service/arquivo_service.dart';
import 'package:sipam_foto/view/foto_widget.dart';

class PontoWidget extends StatefulWidget {
  final PontoModel ponto;
  final VoidCallback? onCameraAberta;
  final VoidCallback? onCameraFechada;
  final VoidCallback? onExcluido;
  const PontoWidget({
    super.key,
    required this.ponto,
    this.onExcluido,
    this.onCameraAberta,
    this.onCameraFechada,
  });

  @override
  State<PontoWidget> createState() => _PontoWidgetState();
}

class _PontoWidgetState extends State<PontoWidget> {
  List<FotoModel> _fotos = [];
  Map<int, File> _arquivos = {};
  bool _carregando = true;

  static const _limiteMetros = 30.0; // ajusta como quiser
  StreamSubscription<Position>? _posSub;
  double? _distancia;

  @override
  void initState() {
    super.initState();
    _carregarFotos();
    _iniciarMonitoramento();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _carregarFotos() async {
    try {
      final fotos = await FotoModel.listarPorPonto(widget.ponto.id);
      final arquivos = <int, File>{};
      for (final foto in fotos) {
        final arquivo = await ArquivoService.getFoto(foto);
        if (arquivo != null) arquivos[foto.id] = arquivo;
      }
      if (!mounted) return;
      setState(() {
        _fotos = fotos.where((f) => arquivos.containsKey(f.id)).toList();
        _arquivos = arquivos;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      _aviso('Erro ao carregar fotos: $e');
    }
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _tirarFoto() async {
    _pararMonitoramento();
    if (!mounted) return;
    widget.onCameraAberta?.call();
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SafeArea(
            child: cam.CameraOverlay(
              titulo: widget.ponto.nome,
              anguloRotacaoDireita: -90,
              anguloRotacaoEsquerda: 90,
              temBotaoGoogleMaps: true,
              temBotaoGaleria: false,
              temMiniMapa: true,
              onFotoFinal: (bytes, localizacao, observacao) async {
                try {
                  await ArquivoService.salvarFoto(
                    pontoId: widget.ponto.id,
                    bytes: bytes,
                    latitude: localizacao?.latitude,
                    longitude: localizacao?.longitude,
                    altitude: localizacao?.altitude,
                    data: localizacao?.data,
                    observacoes: observacao,
                  );
                } catch (e) {
                  _aviso('Erro ao salvar foto: $e');
                }
              },
              onAbrirGaleria: () {},
            ),
          ),
        ),
      );
    } finally {
      widget.onCameraFechada?.call();
      if (mounted) _iniciarMonitoramento();
    }
    await _carregarFotos();
    // voltou da câmera: atualiza o grid
  }

  Future<void> _verFoto(int index) async {
    final alterou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FotoWidget(
          arquivos: _arquivos,
          fotos: _fotos,
          initialIndex: index,
          fotosSelecionadas: const [],
        ),
      ),
    );
    if (alterou == true) await _carregarFotos();
  }

  Future<void> _iniciarMonitoramento() async {
    if (_posSub != null) return;
    var perm = await Geolocator.checkPermission();

    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }

    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return;
    }

    void atualizarDistancia(Position pos) {
      final d = Geolocator.distanceBetween(
        pos.latitude,
        pos.longitude,
        widget.ponto.latitude,
        widget.ponto.longitude,
      );

      if (!mounted) return;
      setState(() => _distancia = d);
    }

    try {
      // Obtém a localização atual sem esperar pelo stream.
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      atualizarDistancia(pos);
    } catch (_) {
      // Se falhar, o stream ainda poderá atualizar a distância.
    }

    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(atualizarDistancia, onError: (_) {});
  }

  Future<void> _pararMonitoramento() async {
    await _posSub?.cancel();
    _posSub = null;
  }

  Future<void> _excluirPonto() async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir ponto?'),
        content: Text(
          'O ponto "${widget.ponto.nome}" e suas ${_fotos.length} foto(s) '
          'serão apagados. Isso não pode ser desfeito.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    try {
      // banco primeiro, pasta depois
      await PontoModel.excluirPonto(widget.ponto.id);
      await ArquivoService.excluirPastaPonto(widget.ponto);
    } catch (e) {
      _aviso('Erro ao excluir ponto: $e');
      return;
    }

    if (!mounted) return;
    widget.onExcluido?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final ponto = widget.ponto;
    final altura = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ponto.nome,
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: _excluirPonto,
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.red,
                  tooltip: 'Excluir ponto',
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${ponto.latitude.toStringAsFixed(6)}, '
              '${ponto.longitude.toStringAsFixed(6)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (_distancia != null && _distancia! > _limiteMetros) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.warning_amber,
                    size: 18,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Você está a ${_distancia!.toStringAsFixed(0)} m do ponto',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: altura * 0.4),
              child: _carregando
                  ? const Center(child: CircularProgressIndicator())
                  : _fotos.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma foto neste ponto ainda',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      itemCount: _fotos.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _verFoto(i),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _arquivos[_fotos[i].id]!,
                            fit: BoxFit.cover,
                            cacheWidth: 300,
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _tirarFoto,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Tirar foto'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
