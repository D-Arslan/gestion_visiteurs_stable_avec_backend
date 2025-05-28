// Code actuel de la page QR à corriger (MobileScanner + attribution QR / marquage départ)
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/visiteur_service.dart';
import '../models/visiteur.dart';
import '../utils/translations.dart';

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
      final index = visiteurs.indexWhere((v) =>
          v.nom == args.nom &&
          v.prenom == args.prenom &&
          v.numeroId == args.numeroId);
      if (index != -1) {
        _visiteurCible = args;
        _indexVisiteur = index;
        isAssigning = true;
        scanEnabled = true;
      }
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!scanEnabled || isScanning) return;

    final barcode = capture.barcodes.first;
    final qrCode = barcode.rawValue;

    if (qrCode == null) return;

    setState(() => isScanning = true);
    controller.stop();

    if (isAssigning) {
      if (_visiteurCible != null && _indexVisiteur != null) {
        final visiteurs = _service.getAll();
        // Autorise la réutilisation d'un QR code uniquement si le visiteur précédent est parti
                  final dejaAttribue = visiteurs.any((v) => v.qrId == qrCode && v.statut != 'Parti');

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
          _service.modifierVisiteur(_indexVisiteur!, modifie);
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

  Future<void> _associerQR(String qrCode) async {
    List<Visiteur> visiteurs = _service.getAll();
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
                onTap: () {
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
                  _service.modifierVisiteur(originalIndex, modifie);
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
  List<Visiteur> visiteurs = _service.getAll();

  // 🔍 On cherche un visiteur ACTUELLEMENT PRÉSENT avec ce QR code
  int index = visiteurs.indexWhere((v) => v.qrId == qrCode && v.statut == 'Présent');

  if (index == -1) {
    _afficherMessage(getText(context, 'qr_not_found'));
    return;
  }

  Visiteur visiteur = visiteurs[index];

  final now = DateTime.now();
  final dateDepart =
      "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} "
      "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

  _service.marquerCommeParti(index, dateDepart);
  _afficherMessage("${visiteur.nom} marqué comme parti");
}

}
