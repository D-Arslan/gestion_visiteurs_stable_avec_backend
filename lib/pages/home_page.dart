import 'package:flutter/material.dart';
import '../utils/translations.dart';
import '../models/visiteur.dart';
import '../services/visiteur_service.dart';
import '../services/visiteur_api_service.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:http/http.dart' as http; // ✅ Ajout : pour les requêtes HTTP
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  List<Visiteur> visiteurs = [];
  final _searchController = TextEditingController();
  final _hiveService = VisiteurService();
  final _apiService = VisiteurApiService();

  List<Map<String, dynamic>> services = [];
  Map<String, dynamic>? selectedService; // à mettre ici, en tant qu'attribut de la classe
bool useApi = true; // ← Change à false pour revenir à Hive
bool isAdding = false;
bool ordreInverse = false;


  @override
  void initState() {
    print("🔁 initState démarré");
    super.initState();
    _loadVisiteurs();
    _checkToken();
    _fetchServices(); // ← Ajout ici

  }

  void _loadVisiteurs() async {
  setState(() => visiteurs = []);

  if (useApi) {
    final data = await _apiService.fetchVisiteurs();
    setState(() {
      visiteurs = data;
    });
  } else {
    setState(() {
      visiteurs = _hiveService.getAll();
    });
  }

  _searchController.clear();
}

void _checkToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  print('Token actuel : $token');
}
Future<void> _fetchServices() async {
  print("📥 _fetchServices appelée");
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  print("🔑 Token récupéré : $token");

final uri = Uri.parse("http://192.168.100.16:8060/api/services");
  try {
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    print("🛠️ Code HTTP services : ${response.statusCode}");
    print("📤 Réponse brute : ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        services = List<Map<String, dynamic>>.from(data);
      });

      print("✅ Liste des services récupérés :");
      for (var s in services) {
        print("- ${s['nomService']}");
      }
    } else {
      print("❌ Erreur HTTP : ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Exception lors du fetch des services : $e");
  }
}
String getNomServiceById(int id) {
  if (services.isEmpty) return "Service inconnu";
  final service = services.firstWhere(
    (s) => s['id'] == id,
    orElse: () => {'nomService': 'Service inconnu'},
  );
  return service['nomService'];
}
Future<String?> scannerQrCodeDansDialog() async {
  String? result;
  bool isChecking = false;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return AlertDialog(
        title: const Text("Scanner le badge"),
        content: SizedBox(
          width: 300,
          height: 300,
          child: MobileScanner(
            onDetect: (capture) async {
              if (isChecking) return;
              isChecking = true;

              final code = capture.barcodes.first.rawValue;
              if (code == null) {
                isChecking = false;
                return;
              }

              final estPris = await _verifierBadgeAttribue(code);

              if (estPris) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Badge déjà attribué."),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                isChecking = false;
              } else {
                result = code;
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      );
    },
  );

  return result;
}
Future<bool> _verifierBadgeAttribue(String qrCode) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  try {
    final idUrl = Uri.parse("http://192.168.100.16:8060/api/visits/by-qrcode?qrCode=$qrCode");
    final idResponse = await http.get(idUrl, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (idResponse.statusCode != 200) return false;

    final int visitId = jsonDecode(idResponse.body);

    final visitUrl = Uri.parse("http://192.168.100.16:8060/api/visits/$visitId");
    final visitResponse = await http.get(visitUrl, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (visitResponse.statusCode != 200) return false;

    final data = jsonDecode(visitResponse.body);
    final status = data['status'];

    return status != 'CLOTURE';
  } catch (e) {
    print("Erreur de vérification du badge : $e");
    return false;
  }
}

  void _ajouterVisiteur() {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _numeroIdController = TextEditingController();

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
              TextField(
                controller: _numeroIdController,
                decoration: const InputDecoration(labelText: "Numéro ID"),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: selectedService,
                hint: const Text("Sélectionner un service"),
                items: services.map((service) {
                  return DropdownMenuItem(
                    value: service,
                    child: Text("${service["nomService"] ?? "Inconnu"}"),
                  );
                }).toList(),
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
                  _numeroIdController.text.trim().isEmpty ||
                  selectedService == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Veuillez remplir tous les champs.")),
                );
                return;
              }

              setState(() => isAdding = true);

              final now = DateTime.now().toIso8601String().substring(0, 16);

              final visiteur = Visiteur(
                nom: _nomController.text.trim(),
                prenom: _prenomController.text.trim(),
                numeroId: _numeroIdController.text.trim(),
                pieceIdentite: '',
                motif: '',
                dateEntree: now,
                statut: "EN COURS",
                dateDepart: null,
                qrId: null,
                serviceId: selectedService!["id"],
                serviceNom: selectedService!["nomService"] ?? "Inconnu",
                satisfaction: 0,
              );

              // ➕ Étape : scan QR
              final qrCode = await scannerQrCodeDansDialog();

              if (qrCode != null) {
                final visiteurComplet = visiteur.copyWith(qrId: qrCode);
                final success = await _apiService.envoyerVisiteur(visiteurComplet);

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Visiteur ajouté avec badge.")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Échec lors de l’envoi du visiteur.")),
                  );
                }
              }

              Navigator.pop(context);
              _loadVisiteurs();
              setState(() => isAdding = false);
            },
            child: const Text("Ajouter"),
          ),
        ],
      );
    },
  );
}




  void _supprimerVisiteur(int index) {
  if (!useApi) {
    _hiveService.supprimerVisiteur(index);
    _loadVisiteurs();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Suppression non disponible côté API.")),
    );
  }
}


  void _marquerCommeParti(int index) {
  if (!useApi) {
    final now = DateTime.now();
    final dateDepart =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    _hiveService.marquerCommeParti(index, dateDepart);
    _loadVisiteurs();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Action non disponible côté API.")),
    );
  }
}


  void _afficherDetails(Visiteur visiteur) {
    visiteur.serviceNom = getNomServiceById(visiteur.serviceId);

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
              Text("Heure d'arrivée : ${visiteur.dateEntree.replaceAll('T', ' ')}", style: const TextStyle(fontSize: 18)),

              if (visiteur.dateDepart != null && visiteur.dateDepart!.isNotEmpty)
  Text(
  "Heure de sortie : ${visiteur.dateDepart?.replaceAll('T', ' ') ?? 'Non renseignée'}",
  style: const TextStyle(fontSize: 18),
),

              Text("Service visité : ${visiteur.serviceNom}", style: const TextStyle(fontSize: 18)),
              Text(
  "Statut : ${visiteur.statut == 'CLOTURE' ? 'Parti' : 'Présent'}",
  style: const TextStyle(fontSize: 18),
),

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
  print("📋 Visiteur reçu pour affichage : ${jsonEncode(visiteur.toJson())}");

}

Future<void> _afficherDetailsDepuisApi(int id) async {
  final apiService = VisiteurApiService();
  final visiteur = await apiService.fetchVisiteurParId(id);

  if (visiteur == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Erreur lors du chargement du visiteur depuis l'API.")),
    );
    return;
  }

  _afficherDetails(visiteur); // On réutilise ta fonction locale une fois le vrai Visiteur récupéré
}


  // === Nouvelle fonction : envoi intelligent vers l'API ===
Future<void> _envoyerVisiteurAuBackend(Map<String, dynamic> visiteur) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final uri = Uri.parse("http://192.168.100.16:8060/api/visits");

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
  /*IconButton(
    icon: Icon(useApi ? Icons.cloud : Icons.storage),
    tooltip: useApi ? 'Mode API activé' : 'Mode local Hive',
    onPressed: () {
      setState(() {
        useApi = !useApi;
      });
      _loadVisiteurs();
    },
  ),*/
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
        "serviceVisite": "Informatique",
        "serviceId": 1,
        "statut": "EN COURS",
        "satisfaction": null,
        "qrCode": "Badge X",
      };
      _envoyerVisiteurAuBackend(testVisiteur);
    },
  ),
  IconButton(
  icon: Icon(Icons.swap_vert),
  tooltip: ordreInverse ? 'Plus anciens d\'abord' : 'Plus récents d\'abord',
  onPressed: () {
    setState(() {
      ordreInverse = !ordreInverse;
      visiteurs = visiteurs.reversed.toList();
    });
  },
),

 /* IconButton(
    icon: const Icon(Icons.file_download),
    tooltip: 'Exporter JSON',
    onPressed: _exporterJSON,
  ),
*/],

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
print("🟨 Visiteur : ${visiteur.nom} - Statut = ${visiteur.statut}");
                      if (_searchController.text.isNotEmpty &&
                          !nom.toLowerCase().contains(_searchController.text.toLowerCase())) {
                        return const SizedBox.shrink();
                      }

                      return ListTile(
                        title: Row(
  children: [
    Text("$nom ${visiteur.prenom}"),
    const SizedBox(width: 6),
    if (visiteur.qrId != null && visiteur.statut == "PRESENT") ...[
  const Icon(Icons.verified, color: Colors.green, size: 18), // ✅ Badge actif
] else if (visiteur.qrId != null && visiteur.statut != "PRESENT") ...[
  const Icon(Icons.block, color: Colors.red, size: 18), // 🔴 Badge libéré
] else ...[
  const Icon(Icons.do_not_disturb_alt, color: Colors.grey, size: 18), // ⚪ Aucun badge
]

,


  ],
),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
Text(
  visiteur.qrId == null
      ? "Aucun badge attribué"
      : (visiteur.statut == "PRESENT"
          ? "Badge attribué"
          : "Badge libéré"),
  style: TextStyle(
    fontSize: 12,
    fontStyle: FontStyle.italic,
    color: visiteur.qrId == null
        ? Colors.grey
        : (visiteur.statut == "PRESENT"
            ? Colors.green
            : Colors.red),
  ),
),



                          ],),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [ // Suppression du bouton de scan 
                            /*IconButton(
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
                            ),*/
                            IconButton(
  icon: const Icon(Icons.logout),
  tooltip: getText(context, 'mark_as_left'),
  onPressed: () {
    if (useApi) {
      marquerCommePartiViaQRCode(); // ⬅️ appel caméra + PUT API
    } else {
      _marquerCommeParti(index); // mode local Hive
    }
  },
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
                        onTap: () {
                          print("🟡 Visiteur cliqué : ${jsonEncode(visiteur)}");
  if (useApi && visiteur.id != null) { // le problème est ici car visiteur.id est null, il faut le récupérer dès le début
    _afficherDetailsDepuisApi(visiteur.id!);
  } else {
    _afficherDetails(visiteur);
  }
},                      );
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
  Future<void> marquerCommePartiViaQRCode() async {
  String? scannedQr;

  // 1. Scanner le QR code
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Scanner le badge pour départ"),
        content: SizedBox(
          width: 300,
          height: 300,
          child: MobileScanner(
            onDetect: (capture) {
              final barcode = capture.barcodes.first;
              if (barcode.rawValue != null) {
                scannedQr = barcode.rawValue;
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      );
    },
  );

  if (scannedQr == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("QR code non scanné.")),
    );
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  try {
    // 2. GET ID depuis le QR code
    final getIdUrl = Uri.parse("http://192.168.100.16:8060/api/visits/by-qrcode?qrCode=$scannedQr");
    final getIdResponse = await http.get(getIdUrl, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (getIdResponse.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la récupération de l'ID (GET 1)")),
      );
      return;
    }

    final int visitId = jsonDecode(getIdResponse.body);

    // 3. GET objet complet
    final getVisitUrl = Uri.parse("http://192.168.100.16:8060/api/visits/$visitId");
    final getVisitResponse = await http.get(getVisitUrl, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (getVisitResponse.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la récupération du visiteur (GET 2)")),
      );
      return;
    }

    final data = jsonDecode(getVisitResponse.body);

    if (data['status'] == 'CLOTURE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visiteur déjà marqué comme parti.")),
      );
      return;
    }

    // 4. Mise à jour de l’objet
    final now = DateTime.now().toIso8601String().substring(0, 16);
    data['exitDate'] = now;
    data['status'] = "CLOTURE";

    // 5. PUT
    final putUrl = Uri.parse("http://192.168.100.16:8060/api/visits/$visitId");
    final putResponse = await http.put(
      putUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    if (putResponse.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Visiteur marqué comme parti.")),
      );
      setState(() {
      _loadVisiteurs(); // recharge la liste
       });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Erreur PUT : ${putResponse.statusCode}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("❌ Exception : $e")),
    );
  }
}


}
