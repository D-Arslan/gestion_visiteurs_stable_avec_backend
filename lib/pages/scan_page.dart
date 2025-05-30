import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import '../utils/translations.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/visiteur.dart';
import '../services/visiteur_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/visiteur_api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';


class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _picker = ImagePicker();
  late Interpreter _interpreter;
  List<String> _labels = [];
  bool _isLoading = false;
  bool _modelLoaded = false;
  File? _lastImage;
  String? _lastResult;
  Map<String, String>? _lastScores;

  Map<String, String>? _mrzFields;

final _apiService = VisiteurApiService();
List<Map<String, dynamic>> services = [];
Map<String, dynamic>? selectedService;


final _service = VisiteurService();

  final int inputSize = 224;

  @override
  void initState() {
    super.initState();
   _fetchServices(); // ← Ajouté
    _loadModel();
  }

Future<void> _fetchServices() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('auth_token');
  final uri = Uri.parse("http://192.168.100.16:8060/api/services");

  try {
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        services = List<Map<String, dynamic>>.from(data);
      });
    }
  } catch (_) {
    // Erreur silencieuse
  }
}
void _ajouterVisiteurViaMRZ(String nom, String prenom, String numero, String type) {
  final now = DateTime.now().toIso8601String().substring(0, 16);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Sélectionner un service"),
        content: DropdownButtonFormField<Map<String, dynamic>>(
          value: selectedService,
          hint: const Text("Choisir un service"),
          items: services.map((service) {
            return DropdownMenuItem(
              value: service,
              child: Text(service['nomService'] ?? 'Inconnu'),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
  if (selectedService == null) return;

  final now = DateTime.now().toIso8601String().substring(0, 16);
  final visiteur = Visiteur(
    nom: nom,
    prenom: prenom,
    pieceIdentite: type,
    numeroId: numero,
    motif: '',
    dateEntree: now,
    statut: "EN COURS",
    dateDepart: null,
    qrId: null,
    serviceId: selectedService!["id"],
    serviceNom: selectedService!["nomService"] ?? "",
    satisfaction: 0,
  );

  Navigator.of(context).pop(); // Ferme la boîte de dialogue du service

  // ➕ Scan du QR code dans la même page
  final qrCode = await scannerQrCodeDansDialog();

  if (qrCode == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("QR code non scanné.")),
    );
    return;
  }

  final visiteurComplet = visiteur.copyWith(qrId: qrCode);

  final success = await _apiService.envoyerVisiteur(visiteurComplet);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(success
          ? "✅ Visiteur ajouté avec badge"
          : "❌ Échec de l'ajout du visiteur"),
    ),
  );
},

            child: const Text("Confirmer"),
          ),
        ],
      );
    },
  );
}
Future<String?> scannerQrCodeDansDialog() async {
  String? result;
  bool isChecking = false;

  await showDialog(
    context: context,
    barrierDismissible: true, // autorise la sortie par l'utilisateur
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

              final estPris = await _verifierBadgeAttribue(code); // ⬅️ on vérifie dans l’API

              if (estPris) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("❌ Badge déjà attribué. Veuillez en scanner un autre."),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                isChecking = false;
              } else {
                result = code;
                Navigator.of(context).pop(); // QR valide → fermeture
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
    // Étape 1 : récupérer l'ID de la visite associée au badge
    final idUrl = Uri.parse("http://192.168.100.16:8060/api/visits/by-qrcode?qrCode=$qrCode");
    final idResponse = await http.get(idUrl, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (idResponse.statusCode != 200) return false; // Pas trouvé → libre

    final int visitId = jsonDecode(idResponse.body);

    // Étape 2 : récupérer le statut de cette visite
    final visitUrl = Uri.parse("http://192.168.100.16:8060/api/visits/$visitId");
    final visitResponse = await http.get(visitUrl, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (visitResponse.statusCode != 200) return false;

    final data = jsonDecode(visitResponse.body);
    final status = data['status'];

    return status != 'CLOTURE'; // true = déjà attribué
  } catch (e) {
    print("Erreur de vérification du badge : $e");
    return false;
  }
}


  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/id_document_classifier.tflite');
      final labelData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelData.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      setState(() => _modelLoaded = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors du chargement du modèle : $e")),
      );
    }
  }

  Future<void> _launchClassification() async {
final picked = await _picker.pickImage(source: ImageSource.camera);
  if (picked == null) return;

  setState(() {
    _isLoading = true;
    _lastImage = File(picked.path);
    _lastResult = null;
    _lastScores = null;
  });

  try {
    final imageBytes = await picked.readAsBytes();
    final image = img.decodeImage(imageBytes);
    if (image == null) throw Exception("Image invalide");

    print("Image chargée : ${image.width}x${image.height}");
print("Format : ${image.format}");

    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    print("Redimensionnée à : ${resized.width}x${resized.height}");

    final input = Float32List(inputSize * inputSize * 3);
    int index = 0;
    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        if (x == 0 && y == 0) {
          print("Pixel[0,0] - R:${pixel.r}, G:${pixel.g}, B:${pixel.b}");
        }
        input[index++] = pixel.r / 255.0;
        input[index++] = pixel.g / 255.0;
        input[index++] = pixel.b / 255.0;
      }
    }

    final moyenne = input.reduce((a, b) => a + b) / input.length;
    print("Moyenne des pixels normalisés : ${moyenne.toStringAsFixed(4)}");

    final inputTensor = input.reshape([1, inputSize, inputSize, 3]);
    final output = List.filled(3, 0.0).reshape([1, 3]);

    _interpreter.run(inputTensor, output);

    final List<double> scores = output[0];
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final labelIndex = scores.indexOf(maxScore);

    final labelMap = {
      "0": "Carte d'identité",
      "1": "Passeport",
      "2": "Permis de conduire",
    };

    final scoresMap = <String, String>{};
    for (int i = 0; i < scores.length; i++) {
      final label = labelMap["$i"] ?? "Inconnu";
      print("$label => ${(scores[i] * 100).toStringAsFixed(2)}%");
      scoresMap[label] = (scores[i] * 100).toStringAsFixed(2);
    }

    setState(() {
      _lastResult = labelMap["$labelIndex"] ?? "Type inconnu";
      _lastScores = scoresMap;
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur lors de la classification : $e")),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getText(context, 'scan'))),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
  icon: const Icon(Icons.document_scanner),
label: Text(getText(context, 'scan_document')),
  onPressed: _modelLoaded ? _launchMRZRecognition : null,
  style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
),
                    if (_lastImage != null) ...[
                      const SizedBox(height: 30),
                      Image.file(_lastImage!, height: 250),
                      const SizedBox(height: 10),
                      if (_lastResult != null)
                        Text(
                          '🧠 Résultat : $_lastResult',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      if (_mrzFields != null)
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: _mrzFields!.entries.map((entry) {
      return Text(
        '${entry.key} : ${entry.value}',
        style: const TextStyle(fontSize: 14),
      );
    }).toList(),
  ),

                      if (_lastScores != null)
                        Column(
                          children: _lastScores!.entries.map((entry) {
                            return Text(
                              '${entry.key} : ${entry.value}%',
                              style: const TextStyle(fontSize: 14),
                            );
                          }).toList(),
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
  // Partie MRZ

Map<String, String> _extractMRZFields(String mrzText) {
  print('🔍 MRZ détecté :\n$mrzText');

  final lines = mrzText
      .replaceAll(' ', '')
      .replaceAll('\r', '')
      .trim()
      .split('\n')
      .where((line) => line.length >= 20)
      .toList();

  if (lines.length < 2) return {'Erreur': 'Aucune MRZ détectée.'};

  String nom = '';
  String prenom = '';
  String numero = '';
  String type = 'Document inconnu';

  final line1 = lines[0];
  final line2 = lines.length > 1 ? lines[1] : '';
  final line3 = lines.length > 2 ? lines[2] : '';

  if (line1.startsWith('IDDZA') || line1.startsWith('DLDZA')) {
    // Carte d'identité ou permis algérien
    numero = line1.substring(5).replaceAll('<', '').trim();
    final nameLine = line3.isNotEmpty ? line3 : line2;
    final nameParts = nameLine.split('<<');
    nom = nameParts[0].replaceAll('<', ' ').trim();
    prenom = nameParts.length > 1 ? nameParts.sublist(1).join(' ').replaceAll('<', ' ').trim() : '';
    type = line1.startsWith('IDDZA') ? 'Carte d\'identité' : 'Permis de conduire';

  } else if (line1.startsWith('P<DZA')) {
    // Passeport algérien
    final namePart = line1.substring(5).split('<<');
    nom = namePart[0].replaceAll('<', ' ').trim();
    prenom = namePart.length > 1 ? namePart[1].replaceAll('<', ' ').trim() : '';

    final match = RegExp(r'^([A-Z0-9]{9,})DZA').firstMatch(line2);
    numero = match != null ? match.group(1)!.trim() : 'Inconnu';
    type = 'Passeport';

  } else {
    return {'Erreur': 'Format MRZ non reconnu'};
  }

  return {
    'Type': type,
    'Numéro': numero,
    'Nom': nom,
    'Prénom': prenom,
  };
}


  Future<void> _launchMRZRecognition() async {
  final picked = await _picker.pickImage(source: ImageSource.camera);
  if (picked == null) return;

  final inputImage = InputImage.fromFilePath(picked.path);
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  try {
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    final String fullText = recognizedText.text;

    // Recherche de lignes MRZ (commençant souvent par P< ou ID<, avec format ICAO)
    final mrzLines = fullText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.length >= 30 && RegExp(r'^[A-Z0-9<]+$').hasMatch(line))
        .toList();

    String mrzResult = mrzLines.join('\n');

    if (mrzResult.isEmpty) {
      mrzResult = "Aucune MRZ détectée. Essayez à nouveau en améliorant la prise de vue..";
    }

final extracted = _extractMRZFields(mrzResult);
final isErreur = extracted.containsKey('Erreur');

setState(() {
  _lastImage = File(picked.path);
  _lastResult = isErreur ? "MRZ non détectée" : "MRZ détectée";
  _mrzFields = extracted;
  _lastScores = null;
});
if (!extracted.containsKey('Erreur')) {
  _ajouterVisiteurViaMRZ(
    extracted['Nom'] ?? '',
    extracted['Prénom'] ?? '',
    extracted['Numéro'] ?? '',
    extracted['Type'] ?? 'Carte Nationale',
  );
}




  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur MRZ : $e")),
    );
  } finally {
    textRecognizer.close();
  }
}

}
