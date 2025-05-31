/// Cette page est désactivée actuellement.
/// Le scan de QR code est désormais géré depuis la HomePage.
/// On la conserve au cas où l’encadrant souhaite la réintégrer.


// Code actuel de la page QR à corriger (MobileScanner + attribution QR / marquage départ)
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/visiteur_service.dart';
import '../models/visiteur.dart';
import '../utils/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QRCodePage extends StatefulWidget {
  const QRCodePage({Key? key}) : super(key: key);

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  final MobileScannerController controller = MobileScannerController();
  final VisiteurService _service = VisiteurService();

  bool isScanning = false;
  bool isAssigning = false;
  bool scanEnabled = false;

  Visiteur? _visiteurCible;
  int? _indexVisiteur;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Visiteur) {
      final visiteurs = _service.getAll();
      
    }
  }
 Future<bool> qrCodeDejaAttribue(String qrCode) async {
  final visiteurs = await fetchVisiteursDepuisApi();
  return visiteurs.any((v) => v.qrId == qrCode && v.statut != 'Parti');
}
  void _onDetect(BarcodeCapture capture) async {
    if (!scanEnabled || isScanning) return;

    final barcode = capture.barcodes.first;
    final qrCode = barcode.rawValue;

    if (qrCode == null) return;

    setState(() => isScanning = true);
    controller.stop();

    if (isAssigning) {
      if (_visiteurCible != null)
 {
       
        // Autorise la réutilisation d'un QR code uniquement si le visiteur précédent est parti
final dejaAttribue = await qrCodeDejaAttribue(qrCode);

        if (_visiteurCible!.qrId != null) {
          _afficherMessage("Ce visiteur a déjà un badge.");
        } else if (dejaAttribue) {
          _afficherMessage("Ce badge est déjà attribué à un autre visiteur.");
        } else {
          final modifie = Visiteur(
            nom: _visiteurCible!.nom,
            prenom: _visiteurCible!.prenom,
            pieceIdentite: _visiteurCible!.pieceIdentite,
            numeroId: _visiteurCible!.numeroId,
            motif: _visiteurCible!.motif,
            dateEntree: _visiteurCible!.dateEntree,
            statut: _visiteurCible!.statut,
            dateDepart: _visiteurCible!.dateDepart,
            serviceId: _visiteurCible!.serviceId,
            serviceNom: _visiteurCible!.serviceNom,
            satisfaction: _visiteurCible!.satisfaction,
            qrId: qrCode,
          );
          //_service.modifierVisiteur(_indexVisiteur!, modifie);
          await associerQrCodeViaApi(modifie.numeroId, qrCode);

          _afficherMessage("QR associé à \${modifie.nom}");
          Navigator.pop(context);
        }

        _visiteurCible = null;
        _indexVisiteur = null;
      } else {
        await _associerQR(qrCode);
      }
    } else {
      await _marquerParti(qrCode);
    }

    await Future.delayed(const Duration(seconds: 1));
    controller.start();
    setState(() => isScanning = false);
  }
Future<List<Visiteur>> fetchVisiteursDepuisApi() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final url = Uri.parse('http://192.168.100.16:8060/api/visits');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body) as List;
    return data.map((json) => Visiteur.fromJson(json)).toList();
  } else {
    _afficherMessage("Erreur lors du chargement des visiteurs.");
    return [];
  }
}

  Future<void> _associerQR(String qrCode) async {
    List<Visiteur> visiteurs = await fetchVisiteursDepuisApi();
List<Visiteur> candidats = visiteurs.where((v) => v.qrId == null && v.statut != 'Parti').toList();

    if (candidats.isEmpty) {
      _afficherMessage(getText(context, 'no_visitor_to_assign'));
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(getText(context, 'choose_visitor'))),
          body: ListView.builder(
            itemCount: candidats.length,
            itemBuilder: (context, index) {
              final visiteur = candidats[index];
              return ListTile(
                title: Text("${visiteur.nom} ${visiteur.prenom}"),
                subtitle: Text(visiteur.motif ?? ""),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  // Vérifie si le QR code est déjà utilisé par un autre visiteur présent
                  final dejaAttribue = visiteurs.any((v) => v.qrId == qrCode && v.statut != 'Parti');
                  if (dejaAttribue) {
                    // Affiche un message d'erreur et annule l'attribution
                    Navigator.pop(context);
                    _afficherMessage("Ce badge est déjà attribué à un autre visiteur.");
                    return;
                  }
                  final modifie = Visiteur(
                    nom: visiteur.nom,
                    prenom: visiteur.prenom,
                    pieceIdentite: visiteur.pieceIdentite,
                    numeroId: visiteur.numeroId,
                    motif: visiteur.motif,
                    dateEntree: visiteur.dateEntree,
                    statut: visiteur.statut,
                    dateDepart: visiteur.dateDepart,
                    serviceId: visiteur.serviceId,
                    serviceNom: visiteur.serviceNom,
                    satisfaction: visiteur.satisfaction,
                    qrId: qrCode,
                  );

                  int originalIndex = visiteurs.indexOf(visiteur);
                  //_service.modifierVisiteur(originalIndex, modifie);
                  await associerQrCodeViaApi(modifie.numeroId, qrCode);

                  Navigator.pop(context);
                  _afficherMessage("QR code associé à ${modifie.nom}");
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _afficherMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getText(context, 'qr_code'))),
      body: Column(
        children: [
          Expanded(
            flex: 4,
            child: MobileScanner(
              controller: controller,
              onDetect: _onDetect,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code),
                  label: Text(getText(context, 'assign_qr')),
                  onPressed: () async {
                    setState(() {
                      isAssigning = true;
                      scanEnabled = true;
                    });
                    controller.start();
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: Text(getText(context, 'scan_to_leave')),
                  onPressed: () async {
                    setState(() {
                      isAssigning = false;
                      scanEnabled = true;
                    });
                    controller.start();
                  },
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.stop_circle),
                  label: Text(scanEnabled
                      ? getText(context, 'stop_scan')
                      : getText(context, 'resume_scan')),
                  onPressed: () async {
                    setState(() {
                      scanEnabled = false;
                      isAssigning = false;
                    });
                    controller.stop();
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _marquerParti(String qrCode) async {
  final visiteurs = await fetchVisiteursDepuisApi();
  final visiteur = visiteurs.firstWhere(
    (v) => v.qrId == qrCode && v.statut == 'Présent',
    orElse: () => Visiteur(nom: '', prenom: '', numeroId: '', dateEntree: '', statut: '', serviceId: 0),
  );

  if (visiteur.nom == '') {
    _afficherMessage(getText(context, 'qr_not_found'));
    return;
  }

  final now = DateTime.now();
  final dateDepart =
      "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} "
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  if (token == null) {
    _afficherMessage("Token JWT non trouvé.");
    return;
  }

  final getUrl = Uri.parse('http://192.168.100.16:8060/api/visits/byNumeroId/${visiteur.numeroId}');
  print("🔍 Appel GET pour récupérer la visite de ${visiteur.numeroId}");
print("🔗 URL : $getUrl");
print("🔐 Token : $token");

  final getResponse = await http.get(
    getUrl,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (getResponse.statusCode != 200) {
    _afficherMessage("Erreur GET pour marquer départ.");
    return;
  }

  final visitData = jsonDecode(getResponse.body);
  final visitId = visitData['id'];

  final putUrl = Uri.parse('http://192.168.100.16:8060/api/visits/$visitId');
  final putBody = jsonEncode({
    'status': 'Parti',
    'exitDate': dateDepart,
  });

  final putResponse = await http.put(
    putUrl,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: putBody,
  );

  if (putResponse.statusCode == 200) {
    _afficherMessage("${visiteur.nom} marqué comme parti");
  } else {
    _afficherMessage("Erreur PUT départ : ${putResponse.statusCode}");
  }
}

Future<void> associerQrCodeViaApi(String numeroId, String qrCode) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');

  if (token == null) {
    _afficherMessage("Token JWT non trouvé.");
    return;
  }

  try {
    final getUrl = Uri.parse('http://192.168.100.16:8060/api/visits/byNumeroId/$numeroId');
    final getResponse = await http.get(
      getUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (getResponse.statusCode != 200) {
      _afficherMessage("Erreur GET visiteur : ${getResponse.statusCode}");
      return;
    }

    final visitData = jsonDecode(getResponse.body);
    if (visitData['id'] == null) {
  _afficherMessage("Identifiant de visite introuvable pour $numeroId");
  return;
}

    final int visitId = visitData['id'];

    final putUrl = Uri.parse('http://192.168.100.16:8060/api/visits/$visitId');
    final putBody = jsonEncode({'qrCode': qrCode});

    final putResponse = await http.put(
      putUrl,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: putBody,
    );

    if (putResponse.statusCode == 200) {
      _afficherMessage("QR code synchronisé côté serveur");
    } else {
      _afficherMessage("Erreur PUT : ${putResponse.statusCode}");
    }

  } catch (e) {
    _afficherMessage("Erreur réseau ou JSON : $e");
  }
}


}
