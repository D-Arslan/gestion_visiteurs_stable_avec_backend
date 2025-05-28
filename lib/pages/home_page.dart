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
  List<Map<String, dynamic>> services = [];


  @override
  void initState() {
    super.initState();
    _loadVisiteurs();
    _checkToken();
    _fetchServices(); // ← Ajout ici

  }

  void _loadVisiteurs() {
    setState(() {
      visiteurs = _service.getAll();
      _searchController.clear();
    });
  }
void _checkToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  print('Token actuel : $token');
}
Future<void> _fetchServices() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final uri = Uri.parse("http://192.168.1.223:8060/api/services");
  final response = await http.get(
    uri,
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print("🟡 Services JSON : $data"); 
    setState(() {
      services = List<Map<String, dynamic>>.from(data);
    });
  } else {
    debugPrint("❌ Erreur de chargement des services : ${response.statusCode}");
  }
}

  void _ajouterVisiteur() {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  Map<String, dynamic>? selectedService;

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Ajouter un visiteur"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomController,
                decoration: const InputDecoration(labelText: "Nom"),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _prenomController,
                decoration: const InputDecoration(labelText: "Prénom"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: selectedService,
                items: services.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text("${service["id"]} - ${service["nom"] ?? "Service inconnu"}"),


                  );
                }).toList(),
                decoration: const InputDecoration(labelText: "Service Visité"),
                onChanged: (val) {
  if (val != null) {
    setState(() {
      selectedService = val;
    });
  }
},

              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nomController.text.trim().isEmpty ||
                  _prenomController.text.trim().isEmpty ||
                  selectedService == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Veuillez remplir tous les champs obligatoires.")),
                );
                return;
              }

              final now = DateTime.now().toIso8601String().substring(0, 16); // Format yyyy-MM-ddTHH:mm

              final visiteur = {
  "nom": _nomController.text,
  "prenom": _prenomController.text,
  "numeroId": null,
  "heureArrivee": now,
  "heureSortie": null,
"nomService": selectedService!["nom"] ?? "Inconnu",
"serviceId": selectedService!["id"] ?? 0,

  "statut": "EN COURS",
  "satisfaction": null,
  "qrCode": null,
};


              await _envoyerVisiteurAuBackend(visiteur);
              _loadVisiteurs();
              Navigator.pop(context);
            },
            child: const Text("Ajouter"),
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
          title: Text("${visiteur.nom} ${visiteur.prenom}"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nom : ${visiteur.nom}", style: const TextStyle(fontSize: 18)),
              Text("Prénom : ${visiteur.prenom}", style: const TextStyle(fontSize: 18)),

              if (visiteur.numeroId != null && visiteur.numeroId!.isNotEmpty)
                Text("Numéro ID : ${visiteur.numeroId}", style: const TextStyle(fontSize: 18)),

              const SizedBox(height: 8),
              Text("Heure d'arrivée : ${visiteur.dateEntree}", style: const TextStyle(fontSize: 18)),

              if (visiteur.dateDepart != null)
                Text("Heure de sortie : ${visiteur.dateDepart}", style: const TextStyle(fontSize: 18)),

              Text("Service visité : ${visiteur.serviceNom}", style: const TextStyle(fontSize: 18)),
              Text("Statut : ${visiteur.statut}", style: const TextStyle(fontSize: 18)),

              if (visiteur.qrId != null)
                Text("QR Code : ${visiteur.qrId}", style: const TextStyle(fontSize: 18))
              else
                const Text("QR Code : Aucun badge attribué",
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.grey)),

              if (visiteur.satisfaction != null)
                Text("Satisfaction : ${visiteur.satisfaction}/5", style: const TextStyle(fontSize: 18))
              else
                const Text("Satisfaction : Non renseignée",
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
      ),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
      transitionDuration: const Duration(milliseconds: 400),
    ),
  ).then((_) => _loadVisiteurs());
}


  // === Nouvelle fonction : envoi intelligent vers l'API ===
Future<void> _envoyerVisiteurAuBackend(Map<String, dynamic> visiteur) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final uri = Uri.parse("http://192.168.1.223:8060/api/visits");

  final response = await http.post(
    uri,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(visiteur),
  );

  if (response.statusCode == 201 || response.statusCode == 200) {
    debugPrint("✅ Visiteur ajouté avec succès.");
  } else {
    debugPrint("❌ Échec de l'ajout : ${response.statusCode} - ${response.body}");
  }
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
            onPressed: () {
  final now = DateTime.now().toIso8601String().substring(0, 16);
  final testVisiteur = {
    "nom": "Test",
    "prenom": "Utilisateur",
    "numeroId": null,
    "heureArrivee": now,
    "heureSortie": null,
    "serviceVisite": "Informatique", // Assure-toi que ce service existe
    "serviceId": 1, // Un ID valide du backend
    "statut": "EN COURS",
    "satisfaction": null,
    "qrCode": null,
  };

  _envoyerVisiteurAuBackend(testVisiteur);
},

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
Text("${visiteur.serviceNom} | ${visiteur.dateEntree} | ${visiteur.statut}"),
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
