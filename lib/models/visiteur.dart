class Visiteur {
  String nom;
  String prenom;
  String? pieceIdentite;
  String numeroId;
  String? motif;
  String dateEntree;
  String statut;
  String? dateDepart;
  String? qrId;

  int? id;
  String serviceNom;
  int serviceId;
  int? satisfaction;

  Visiteur({
    required this.nom,
    required this.prenom,
    this.pieceIdentite,
    required this.numeroId,
    this.motif,
    required this.dateEntree,
    required this.statut,
    this.dateDepart,
    this.qrId,
    this.id,
    this.serviceNom = '',
    required this.serviceId,
    this.satisfaction,
  });

  /// Pour Hive
  Map<String, dynamic> toMap() => {
    'nom': nom,
    'prenom': prenom,
    'pieceIdentite': pieceIdentite,
    'numeroId': numeroId,
    'motif': motif,
    'dateEntree': dateEntree,
    'statut': statut,
    'dateDepart': dateDepart,
    'qrId': qrId,
    'id': id,
    'serviceNom': serviceNom,
    'serviceId': serviceId,
    'satisfaction': satisfaction,
  };

  factory Visiteur.fromMap(Map<dynamic, dynamic> map) => Visiteur(
    nom: map['nom'],
    prenom: map['prenom'],
    pieceIdentite: map['pieceIdentite'],
    numeroId: map['numeroId'],
    motif: map['motif'],
    dateEntree: map['dateEntree'],
    statut: map['statut'],
    dateDepart: map['dateDepart'],
    qrId: map['qrId'],
    id: map['id'],
    serviceNom: map['serviceNom'] ?? '',
    serviceId: map['serviceId'] ?? 0,
    satisfaction: map['satisfaction'],
  );

  /// Pour backend : JSON reçu en GET
  factory Visiteur.fromJson(Map<String, dynamic> json) => Visiteur(
  nom: json['nom'] ?? '',
  prenom: json['prenom'] ?? '',
  numeroId: json['numeroId'] ?? '',
  statut: json['statut'] ?? json['status'] ?? '',
  dateEntree: json['visitDate'] ?? '',
  dateDepart: json['exitDate'],
  qrId: json['qrCode'],
  id: json['idVisit'] ?? json['id'], // ← selon le nom exact renvoyé
  serviceId: json['serviceId'] ?? json['service']?['id'] ?? 0,
  serviceNom: json['nomService'] ?? json['service']?['nom'] ?? '',
  satisfaction: json['satisfaction'],
  pieceIdentite: json['pieceIdentite'],
  motif: json['motif'],
);


  /// Pour envoi général si besoin (complet)
  Map<String, dynamic> toJson() => {
    "id": id,
    "nom": nom,
    "prenom": prenom,
    "numeroId": numeroId,
    "heureArrivee": dateEntree,
    "heureSortie": dateDepart ?? "",
    "serviceVisite": serviceNom, // enlevé 
    "serviceId": serviceId,
    "statut": statut,
    "satisfaction": satisfaction,
    "qrCode": qrId,
    "pieceIdentite": pieceIdentite,
    "motif": motif,
  };

  /// ✅ Pour POST vers l’API — clean
  Map<String, dynamic> toJsonForPost() => {
  "nom": nom,
  "prenom": prenom,
  "numeroId": numeroId,
  "heureArrivee": (dateEntree.trim().isEmpty) ? null : dateEntree,
  "heureSortie": null, // explicitement nul
  "serviceId": serviceId,
  "statut": "PRESENT", // attention : ce statut doit exister dans ton enum Java
  "satisfaction": null,
  "qrCode": qrId,
};

// modifier un champ en gardant les autres 
Visiteur copyWith({
  String? nom,
  String? prenom,
  String? pieceIdentite,
  String? numeroId,
  String? motif,
  String? dateEntree,
  String? statut,
  String? dateDepart,
  String? qrId,
  int? id,
  String? serviceNom,
  int? serviceId,
  int? satisfaction,
}) {
  return Visiteur(
    nom: nom ?? this.nom,
    prenom: prenom ?? this.prenom,
    pieceIdentite: pieceIdentite ?? this.pieceIdentite,
    numeroId: numeroId ?? this.numeroId,
    motif: motif ?? this.motif,
    dateEntree: dateEntree ?? this.dateEntree,
    statut: statut ?? this.statut,
    dateDepart: dateDepart ?? this.dateDepart,
    qrId: qrId ?? this.qrId,
    id: id ?? this.id,
    serviceNom: serviceNom ?? this.serviceNom, // enlevé
    serviceId: serviceId ?? this.serviceId,
    satisfaction: satisfaction ?? this.satisfaction,
  );
}

}
