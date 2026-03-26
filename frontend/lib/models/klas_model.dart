class KlasModel {
  final int id;
  final String naam;
  final int docentId;
  final DateTime createdAt;
  final int leerlingCount;

  KlasModel({
    required this.id,
    required this.naam,
    required this.docentId,
    required this.createdAt,
    this.leerlingCount = 0,
  });

  factory KlasModel.fromJson(Map<String, dynamic> json) {
    return KlasModel(
      id: json['id'],
      naam: json['naam'],
      docentId: json['docent_id'],
      createdAt: DateTime.parse(json['created_at']),
      leerlingCount: json['leerling_count'] ?? 0,
    );
  }
}

class LeerlingModel {
  final int id;
  final String voornaam;
  final String achternaam;
  final int klasId;
  final DateTime createdAt;

  LeerlingModel({
    required this.id,
    required this.voornaam,
    required this.achternaam,
    required this.klasId,
    required this.createdAt,
  });

  String get volledigeNaam => '$voornaam $achternaam';

  factory LeerlingModel.fromJson(Map<String, dynamic> json) {
    return LeerlingModel(
      id: json['id'],
      voornaam: json['voornaam'],
      achternaam: json['achternaam'],
      klasId: json['klas_id'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
