import 'package:flutter/material.dart';
import 'package:sipam_foto/model/filtro.dart' as model;
import 'package:sipam_foto/model/missao_model.dart';

class Filtros extends StatefulWidget {
  final model.Filtro filtro;
  const Filtros({super.key, required this.filtro});

  @override
  State<Filtros> createState() => _FiltrosState();
}

class _FiltrosState extends State<Filtros> {
  late model.Filtro filtro;
  late TextEditingController _nomeController;
  DateTime? _inicio;
  DateTime? _fim;
  double _min = 0;
  double _max = 2000;
  RangeValues _altitudeRange = const RangeValues(0, 2000);
  List<MissaoModel> missoes = [];
  bool loadingMissoes = true;

  @override
  void initState() {
    super.initState();
    filtro = widget.filtro;
    _loadMissoes();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _loadMissoes() async {
    final lista = await MissaoModel.listar();
    setState(() {
      missoes = lista;
      loadingMissoes = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loadingMissoes) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        spacing: 3,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Filtros',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<int>(
            key: ValueKey(filtro.missaoId ?? -1),
            initialValue: filtro.missaoId ?? -1,
            style: TextStyle(color: Colors.white),
            dropdownColor: const Color.fromARGB(255, 40, 50, 70),
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Missão',
              filled: false,

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: [
              const DropdownMenuItem<int>(
                value: -1,
                child: Text('Todas as missões'),
              ),
              ...missoes.map(
                (m) => DropdownMenuItem<int>(value: m.id, child: Text(m.nome)),
              ),
            ],
            onChanged: (v) {
              if (v == -1) {
                setState(() {
                  filtro = filtro.copyWith(missaoId: null, limparMissao: true);
                });
              } else {
                setState(() {
                  filtro = filtro.copyWith(missaoId: v);
                });
              }
            },
          ),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    _inicio = await showDatePicker(
                      context: context,
                      initialDate: filtro.inicio ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (_inicio != null) {
                      setState(() {
                        filtro = filtro.copyWith(inicio: _inicio);
                      });
                    }
                  },
                  child: Text(
                    filtro.inicio == null
                        ? 'Data inicial'
                        : 'Início: ${filtro.inicio!.day}/${filtro.inicio!.month}/${filtro.inicio!.year}',
                  ),
                ),
              ),
              const SizedBox(width: 8), // espaço entre os botões
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    _fim = await showDatePicker(
                      context: context,
                      initialDate: filtro.fim ?? DateTime.now(),
                      firstDate: filtro.inicio ?? DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (_fim != null) {
                      setState(() {
                        filtro = filtro.copyWith(fim: _fim);
                      });
                    }
                  },
                  child: Text(
                    filtro.fim == null
                        ? 'Data final'
                        : 'Fim: ${filtro.fim!.day}/${filtro.fim!.month}/${filtro.fim!.year}',
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context, model.Filtro.empty);
                  },
                  child: const Text('Limpar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, filtro);
                  },
                  child: const Text('Aplicar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
