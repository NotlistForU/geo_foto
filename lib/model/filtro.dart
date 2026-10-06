class Filtro {
  final DateTime? inicio;
  final DateTime? fim;
  final int? missaoId;
  final int? pontoId;

  const Filtro({this.inicio, this.fim, this.missaoId, this.pontoId});

  static const Filtro empty = Filtro();

  bool get isEmpty {
    return inicio == null && fim == null && missaoId == null && pontoId == null;
  }

  Filtro copyWith({
    DateTime? inicio,
    DateTime? fim,
    int? missaoId,
    int? pontoId,
    bool limparMissao = false,
    bool limparPonto = false,
    bool limparNome = false,
  }) {
    return Filtro(
      inicio: inicio ?? this.inicio,
      fim: fim ?? this.fim,
      missaoId: limparMissao ? null : (missaoId ?? this.missaoId),
      pontoId: limparPonto ? null : (pontoId ?? this.pontoId),
    );
  }
}
