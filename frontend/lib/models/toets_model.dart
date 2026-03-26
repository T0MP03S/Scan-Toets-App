class VraagModel {
  final int nummer;
  final String vraag;
  final String correctAntwoord;
  final int punten;

  VraagModel({
    required this.nummer,
    required this.vraag,
    required this.correctAntwoord,
    required this.punten,
  });

  factory VraagModel.fromJson(Map<String, dynamic> json) {
    return VraagModel(
      nummer: json['nummer'],
      vraag: json['vraag'],
      correctAntwoord: json['correct_antwoord'],
      punten: json['punten'],
    );
  }

  Map<String, dynamic> toJson() => {
    'nummer': nummer,
    'vraag': vraag,
    'correct_antwoord': correctAntwoord,
    'punten': punten,
  };
}

class ToetsModel {
  final int id;
  final String titel;
  final String vak;
  final String? beschrijving;
  final int klasId;
  final String klasNaam;
  final int docentId;
  final Map<String, dynamic>? masterDataJson;
  final int? totaalPunten;
  final DateTime createdAt;

  ToetsModel({
    required this.id,
    required this.titel,
    required this.vak,
    this.beschrijving,
    required this.klasId,
    this.klasNaam = '',
    required this.docentId,
    this.masterDataJson,
    this.totaalPunten,
    required this.createdAt,
  });

  List<VraagModel> get vragen {
    if (masterDataJson == null) return [];
    final list = masterDataJson!['vragen'] as List? ?? [];
    return list.map((v) => VraagModel.fromJson(v)).toList();
  }

  int get aantalVragen => vragen.length;
  bool get heeftAntwoordmodel => masterDataJson != null && vragen.isNotEmpty;

  factory ToetsModel.fromJson(Map<String, dynamic> json) {
    return ToetsModel(
      id: json['id'],
      titel: json['titel'],
      vak: json['vak'],
      beschrijving: json['beschrijving'],
      klasId: json['klas_id'],
      klasNaam: json['klas_naam'] ?? '',
      docentId: json['docent_id'] ?? 0,
      masterDataJson: json['master_data_json'],
      totaalPunten: json['totaal_punten'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class ToetsListModel {
  final int id;
  final String titel;
  final String vak;
  final String? beschrijving;
  final int klasId;
  final String klasNaam;
  final int? totaalPunten;
  final int aantalVragen;
  final DateTime createdAt;

  ToetsListModel({
    required this.id,
    required this.titel,
    required this.vak,
    this.beschrijving,
    required this.klasId,
    this.klasNaam = '',
    this.totaalPunten,
    this.aantalVragen = 0,
    required this.createdAt,
  });

  factory ToetsListModel.fromJson(Map<String, dynamic> json) {
    return ToetsListModel(
      id: json['id'],
      titel: json['titel'],
      vak: json['vak'],
      beschrijving: json['beschrijving'],
      klasId: json['klas_id'],
      klasNaam: json['klas_naam'] ?? '',
      totaalPunten: json['totaal_punten'],
      aantalVragen: json['aantal_vragen'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
