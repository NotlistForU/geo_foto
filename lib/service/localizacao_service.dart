import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class LocalizacaoService {
  static const _distance = Distance();

  static Future<Position> posicaoAtual() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('GPS desligado');
    }

    var permissao = await Geolocator.checkPermission();
    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();
    }
    if (permissao == LocationPermission.denied ||
        permissao == LocationPermission.deniedForever) {
      throw Exception('Sem permissão de localização');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Distância em metros entre dois pontos.
  static double metros(LatLng a, LatLng b) =>
      _distance.as(LengthUnit.Meter, a, b);

  static Future<PosicaoPrecisa> posicaoPrecisa({
    Duration tempo = const Duration(seconds: 8),
    double precisaoAlvo = 10,
    int minAmostras = 3,
  }) async {
    await posicaoAtual(); // garante GPS ligado + permissão

    final LocationSettings settings =
        defaultTargetPlatform == TargetPlatform.android
        ? AndroidSettings(
            accuracy: LocationAccuracy.best,
            intervalDuration: const Duration(seconds: 1),
          )
        : const LocationSettings(accuracy: LocationAccuracy.best);

    final amostras = <Position>[];
    final sub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(amostras.add);

    final fim = DateTime.now().add(tempo);
    while (DateTime.now().isBefore(fim)) {
      await Future.delayed(const Duration(milliseconds: 300));
      final boas = amostras.where((p) => p.accuracy <= precisaoAlvo).length;
      if (boas >= minAmostras) break;
    }
    await sub.cancel();

    // plano B: se o stream não entregou nada, pega uma leitura direta
    if (amostras.isEmpty) {
      amostras.add(await posicaoAtual());
    }

    // usa as boas; se não tiver nenhuma, as 3 melhores que apareceram
    var usadas = amostras.where((p) => p.accuracy <= precisaoAlvo).toList();
    if (usadas.isEmpty) {
      amostras.sort((a, b) => a.accuracy.compareTo(b.accuracy));
      usadas = amostras.take(3).toList();
    }

    double somaW = 0, lat = 0, lng = 0, alt = 0;
    for (final p in usadas) {
      final acc = p.accuracy <= 0 ? 1.0 : p.accuracy;
      final w = 1 / (acc * acc);
      somaW += w;
      lat += p.latitude * w;
      lng += p.longitude * w;
      alt += p.altitude * w;
    }

    final melhor = usadas
        .map((p) => p.accuracy)
        .reduce((a, b) => a < b ? a : b);

    return PosicaoPrecisa(
      latitude: lat / somaW,
      longitude: lng / somaW,
      altitude: alt / somaW,
      precisao: melhor,
    );
  }
}

class PosicaoPrecisa {
  final double latitude;
  final double longitude;
  final double altitude;
  final double precisao; // metros

  const PosicaoPrecisa({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.precisao,
  });
}
