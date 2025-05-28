import 'package:flutter/material.dart';
import '../models/visiteur.dart';
import '../utils/translations.dart';

class VisiteurTile extends StatelessWidget {
  final Visiteur visiteur;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onMarkAsLeft;

  const VisiteurTile({
    required this.visiteur,
    required this.onTap,
    required this.onDelete,
    required this.onMarkAsLeft,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(visiteur.nom),
      subtitle: Text("${visiteur.motif} | ${visiteur.dateEntree} | ${visiteur.statut}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: Icon(Icons.logout), onPressed: onMarkAsLeft),
          IconButton(icon: Icon(Icons.delete), onPressed: onDelete),
        ],
      ),
      onTap: onTap,
    );
  }
}
