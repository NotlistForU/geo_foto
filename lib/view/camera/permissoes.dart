import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

/// 1. Permissão da câmera
Future<bool> requestCameraPermission() async {
  final status = await Permission.camera.status;
  if (!status.isGranted) {
    final result = await Permission.camera.request();
    if (!result.isGranted) {
      return false;
    }
  }
  return true;
}

/// 2. Permissão de localização
Future<bool> requestLocationPermission() async {
  final status = await Permission.locationWhenInUse.status;
  if (!status.isGranted) {
    final result = await Permission.locationWhenInUse.request();
    if (!result.isGranted) {
      return false;
    }
  }

  // Verifica se o serviço de localização está ativo
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return false;
  }

  return true;
}

/// 3. Permissão da galeria (PhotoManager)
Future<bool> requestGalleryPermission() async {
  final result = await PhotoManager.requestPermissionExtend();
  return result.isAuth;
}

/// 4. Função que chama todas
Future<bool> requestAllPermissions() async {
  final cameraOk = await requestCameraPermission();
  final locationOk = await requestLocationPermission();
  final galleryOk = await requestGalleryPermission();

  return cameraOk && locationOk && galleryOk;
}
