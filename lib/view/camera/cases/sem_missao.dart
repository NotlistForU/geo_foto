import 'package:flutter/material.dart';
import 'package:sipam_foto/view/camera/enum.dart';
import 'package:sipam_foto/view/missao/missao.dart' as page;

class SemMissao extends StatelessWidget {
  final void Function(CameraStatus) onSetState;
  final VoidCallback onInitFluxo;
  const SemMissao({
    super.key,
    required this.onSetState,
    required this.onInitFluxo,
  });

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: AppBar(title: const Text('Câmera')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.push(
              c,
              MaterialPageRoute(builder: (_) => const page.Missao()),
            );
            onSetState(CameraStatus.loading);
            onInitFluxo();
          },
          child: const Text('Ativar missão'),
        ),
      ),
    );
  }
}
