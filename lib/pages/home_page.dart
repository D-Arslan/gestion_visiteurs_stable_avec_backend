import 'package:flutter/material.dart';
import '../utils/translations.dart';
import '../models/visiteur.dart';
import '../services/visiteur_service.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http; // ✅ Ajout : pour les requêtes HTTP
import 'package:shared_preferences/shared_preferences.dart';



class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Visiteur> visiteurs = [];
  final _searchController = TextEditingController();
  final _service = VisiteurService();

  @override
  void initState() {
    super.initState();
    _loadVisiteurs();
  }

  void _loadVisiteurs() {
    setState(() {
      visiteurs = _service.getAll();
      _searchController.clear();
    });
  }

  void _ajouterVisiteur() {
    final _nomController = TextEditingController();
    final _prenomController = TextEditingController();
    final _idNumberController = TextEditingController();
    String _selectedMotif = 'Réunion';
    String _selectedPiece = 'Carte Nationale';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(getText(context, 'add_visitor')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nomController,
                  decoration: InputDecoration(labelText: getText(context, 'visitor_name')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _prenomController,
                  decoration: InputDecoration(labelText: getText(context, 'visitor_first_name')),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedMotif,
                  decoration: InputDecoration(labelText: getText(context, 'reason')),
                  items: ["Réunion", "Stage", "Visite de courtoisie", "Autre"]
                      .map((motif) => DropdownMenuItem(
                            value: motif,
                            child: Text(motif),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) _selectedMotif = val;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedPiece,
                  decoration: InputDecoration(labelText: getText(context, 'identification_type')),
                  items: ["Carte Nationale", "Passeport", "Permis de conduire"]
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) _selectedPiece = val;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _idNumberController,
                  decoration: InputDecoration(labelText: getText(context, 'identification_number')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(getText(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nomController.text.trim().isEmpty || _prenomController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(getText(context, 'name_required'))),
                  );
                  return;
                }

                final now = DateTime.now();
                final dateEntree =
                    "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

                final nouveau = Visiteur(
                  nom: _nomController.text,
                  prenom: _prenomController.text,
                  pieceIdentite: _selectedPiece,
                  numeroId: _idNumberController.text,
                  motif: _selectedMotif,
                  dateEntree: dateEntree,
                  statut: "Présent",
                  // === Champs ajoutés ===
                  serviceId: 0,
                  serviceNom: '',
                  satisfaction: 5,
                );

                _service.ajouterVisiteur(nouveau);
                _loadVisiteurs();
                Navigator.pop(context);
              },
              child: Text(getText(context, 'add')),
            ),
          ],
        );
      },
    );
  }

  void _supprimerVisiteur(int index) {
    _service.supprimerVisiteur(index);
    _loadVisiteurs();
  }

  void _marquerCommeParti(int index) {
    final now = DateTime.now();
    final dateDepart =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    _service.marquerCommeParti(index, dateDepart);
    _loadVisiteurs();
  }

  void _afficherDetails(Visiteur visiteur) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Scaffold(
          appBar: AppBar(
        // ✅ Ajout du bouton d'envoi à l'API
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Envoyer vers API',
            onPressed: _envoyerVisiteurs,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exporter JSON',
            onPressed: _exporterJSON,
          ),
        ],title: Text(visiteur.nom + visiteur.prenom)),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${getText(context, 'visitor_name')}: ${visiteur.nom}", style: const TextStyle(fontSize: 18)),
                Text("${getText(context, 'visitor_first_name')}: ${visiteur.prenom}", style: const TextStyle(fontSize: 18)),
                Text("${getText(context, 'identification_type')}: ${visiteur.pieceIdentite}", style: const TextStyle(fontSize: 18)),
                Text("${getText(context, 'identification_number')}: ${visiteur.numeroId}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("${getText(context, 'reason')}: ${visiteur.motif}", style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text("Date: ${visiteur.dateEntree}", style: const TextStyle(fontSize: 18)),
                Text("Statut: ${visiteur.statut}", style: const TextStyle(fontSize: 18)),
                if (visiteur.dateDepart != null) ...[
                  Text("Date de départ: ${visiteur.dateDepart}", style: const TextStyle(fontSize: 18)),
                ],
                if (visiteur.qrId != null) ...[
                  Text("QR ID: ${visiteur.qrId}", style: const TextStyle(fontSize: 18)), // ✅ Affiche le QR ID s’il existe
                ] else ...[
                  Text("QR ID : Aucun badge attribué", style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
              ],
            ),
          ),
        ),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    ).then((_) => _loadVisiteurs());
  }

  // === Nouvelle fonction : envoi intelligent vers l'API ===
Future<void> _envoyerVisiteurs() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Token manquant. Connectez-vous.")),
    );
    return;
  }

  final box = Hive.box('visiteurs');
  final liste = box.values.map((v) => Map<String, dynamic>.from(v)).toList();

  for (var visiteur in liste) {
    final isSorti = visiteur['dateDepart'] != null && visiteur['dateDepart'].toString().isNotEmpty;
    final id = visiteur['id'] ?? 0;

    final jsonBody = jsonEncode({
      'nom': visiteur['nom'],
      'prenom': visiteur['prenom'],
      'numeroId': visiteur['numeroId'],
      'heureArrivee': convertDateToSQLFormat(visiteur['dateEntree']),
      'serviceId': visiteur['serviceId'],
      'QRcode': visiteur['qrId'],
      if (isSorti) 'exitDate': convertDateToSQLFormat(visiteur['dateDepart']),
    });

    try {
      final uri = isSorti
          ? Uri.parse('http://192.168.1.223:8060/api/visits/$id')
          : Uri.parse('http://192.168.1.223:8060/api/visits');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
  print("🔐 Token utilisé : $token");
  print("📤 URL utilisée : $uri");
  print("📤 Headers : $headers");
  print("📦 Corps JSON : $jsonBody");
      final response = isSorti
      
          ? await http.put(uri, headers: headers, body: jsonBody)
          : await http.post(uri, headers: headers, body: jsonBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("✅ Données envoyées pour ${visiteur['nom']}");
      } else {
        debugPrint("❌ (${response.statusCode}) : ${response.body}");
      }
    } catch (e) {
      debugPrint("❗ Erreur : $e");
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Données envoyées à l'API")),
  );
}



  // === Fonction déjà existante ===
  String convertDateToSQLFormat(String input) {
    try {
      final parts = input.split(" ");
      final dateParts = parts[0].split("/");
      final formatted = "${dateParts[2]}-${dateParts[1].padLeft(2, '0')}-${dateParts[0].padLeft(2, '0')}T${parts[1]}:00"; // ✅ T ajouté pour format ISO 8601
      return formatted;
    } catch (_) {
      return input;
    }
  }

void _exporterJSON() {
  final box = Hive.box('visiteurs');
  final liste = box.values.map((v) => Map<String, dynamic>.from(v)).map((visiteur) => {
    'nom': visiteur['nom'],
    'prenom': visiteur['prenom'],
    'numeroId': visiteur['numeroId'],
    'heureArrivee': convertDateToSQLFormat(visiteur['dateEntree']),
    'serviceId': visiteur['serviceId'],
    'QRcode': visiteur['qrId'],

  }).toList();


    final json = jsonEncode(liste);
    print("=== Export JSON ===\n$json");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Export JSON affiché dans la console")),
    );
  }

  @override
  Widget build(BuildContext context) {
    // === Ajout : bouton d'envoi vers API ===
    
    return Scaffold(
      appBar: AppBar(
        title: Text(getText(context, 'visitor_list')),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Envoyer vers API',
            onPressed: _envoyerVisiteurs,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            tooltip: 'Exporter JSON',
            onPressed: _exporterJSON,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: getText(context, 'search'),
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: visiteurs.isEmpty
                ? Center(child: Text(getText(context, 'empty_visitor_list')))
                : ListView.builder(
                    itemCount: visiteurs.length,
                    itemBuilder: (context, index) {
                      final visiteur = visiteurs[index];
                      final nom = visiteur.nom;

                      if (_searchController.text.isNotEmpty &&
                          !nom.toLowerCase().contains(_searchController.text.toLowerCase())) {
                        return const SizedBox.shrink();
                      }

                      return ListTile(
                        title: Row(
                          children: [
                            Text("$nom ${visiteur.prenom}"),
                            const SizedBox(width: 6),
                            if (visiteur.qrId != null && visiteur.statut == 'Parti') ...[
                              const Icon(Icons.block, color: Colors.orange, size: 18), // 🟠 Badge libéré
                            ] else if (visiteur.qrId != null) ...[
                              const Icon(Icons.verified, color: Colors.green, size: 18), // 🟢 Badge actif
                            ] else ...[
                              const Icon(Icons.do_not_disturb_alt, color: Colors.grey, size: 18), // ⚪ Aucun badge
                            ],
                          ],),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${visiteur.motif} | ${visiteur.dateEntree} | ${visiteur.statut}"),
                            Text(
                              visiteur.qrId != null && visiteur.statut == 'Parti'
                                  ? "Badge libéré"
                                  : visiteur.qrId != null
                                      ? "Badge attribué"
                                      : "Aucun badge attribué",
                              style: TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: visiteur.qrId != null && visiteur.statut == 'Parti'
                                  ? Colors.orange
                                  : visiteur.qrId != null
                                      ? Colors.green
                                      : Colors.grey,
                              ),
                            ),
                          ],),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.qr_code),
                              tooltip: 'Attribuer un badge',
                              onPressed: () {
                                if (visiteur.qrId != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Badge déjà attribué à ${visiteur.nom}')),
                                  );
                                } else {
                                  Navigator.pushNamed(context, '/qr_scan', arguments: visiteur);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout),
                              tooltip: getText(context, 'mark_as_left'),
                              onPressed: () => _marquerCommeParti(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text(getText(context, 'confirm_delete')),
                                    content: Text(getText(context, 'delete_message')),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: Text(getText(context, 'cancel')),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          _supprimerVisiteur(index);
                                        },
                                        child: Text(getText(context, 'delete')),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        onTap: () => _afficherDetails(visiteur),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _ajouterVisiteur,
        child: const Icon(Icons.add),
        tooltip: getText(context, 'add_visitor'),
      ),
    );
  }
}
