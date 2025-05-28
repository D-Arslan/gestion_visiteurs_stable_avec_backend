class Visiteur {
  String nom;
  String prenom;
  String pieceIdentite; // carte nationale, passeport, permis de conduire
  String numeroId;
  String motif;
  String dateEntree;
  String statut;
  String? dateDepart;
  String? qrId;

  // === Champs ajoutés pour correspondre au format API ===
  int? id;
  String serviceNom = "";
  int serviceId = 0;
  int satisfaction = 0;

  Visiteur({
    required this.nom,
    required this.prenom,
    required this.pieceIdentite,
    required this.numeroId,
    required this.motif,
    required this.dateEntree,
    required this.statut,
    this.dateDepart,
    this.qrId,
    this.id,
    this.serviceNom = "",
    this.serviceId = 0,
    this.satisfaction = 0,
  });

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
    // === Champs ajoutés ===
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
    // === Champs ajoutés ===
    id: map['id'],
    serviceNom: map['serviceNom'] ?? '',
    serviceId: map['serviceId'] ?? 0,
    satisfaction: map['satisfaction'] ?? 0,
  );

  // === Méthode ajoutée pour l'export API ===
  Map<String, dynamic> toJson() {
    return {
      "id": id ?? 0,
      "nom": nom,
      "prenom": prenom,
      "numeroId": numeroId,
      "heureArrivee": dateEntree,
      "heureSortie": dateDepart ?? "",
      "serviceVisite": serviceNom,
      "serviceId": serviceId,
      "statut": statut,
      "satisfaction": satisfaction,
    };
  }
} 
