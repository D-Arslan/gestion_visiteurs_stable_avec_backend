import 'package:hive/hive.dart';
import '../models/visiteur.dart';

class VisiteurService {
  final _box = Hive.box('visiteurs');

  List<Visiteur> getAll() {
    return _box.values
        .map((e) => Visiteur.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  void ajouterVisiteur(Visiteur visiteur) {
    _box.add(visiteur.toMap());
  }

  void supprimerVisiteur(int index) {
    if (index >= 0 && index < _box.length) {
      _box.deleteAt(index);
    }
  }

  void marquerCommeParti(int index, String dateDepart) {
    final liste = getAll();
    if (index >= 0 && index < liste.length) {
      final v = liste[index];
      final misAJour = Visiteur(
        nom: v.nom,
        prenom: v.prenom,
        pieceIdentite: v.pieceIdentite,
        numeroId: v.numeroId,
        motif: v.motif,
        dateEntree: v.dateEntree,
        statut: 'Parti',
        dateDepart: dateDepart,
        qrId: v.qrId,
        // === Champs ajoutés pour ne rien perdre ===
        id: v.id,
        serviceNom: v.serviceNom,
        serviceId: v.serviceId,
        satisfaction: v.satisfaction,
      );
      _box.putAt(index, misAJour.toMap());
    }
  }

  void modifierVisiteur(int index, Visiteur modifie) {
    _box.putAt(index, modifie.toMap());
  }
} 
