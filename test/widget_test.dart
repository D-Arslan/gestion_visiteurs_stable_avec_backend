// home_page.dart
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/translations.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> visiteurs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadVisiteurs();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadVisiteurs();
  }

  @override
  void deactivate() {
    _saveVisiteurs();
    super.deactivate();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadVisiteurs() {
    final box = Hive.box('visiteurs');
    final data = box.values.cast<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    setState(() => visiteurs = data);
  }

  void _saveVisiteurs() {
    final box = Hive.box('visiteurs');
    box.clear();
    for (var v in visiteurs) {
      box.add(v);
    }
  }

  void _ajouterVisiteur() {
    TextEditingController _nomController = TextEditingController();
    String _selectedMotif = 'Réunion';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(getText(context, 'add_visitor')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nomController,
                decoration: InputDecoration(labelText: getText(context, 'visitor_name')),
              ),
              SizedBox(height: 12),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(getText(context, 'cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nomController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(getText(context, 'name_required'))),
                  );
                  return;
                }
                final now = DateTime.now();
                final dateEntree =
                    "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
                setState(() {
                  visiteurs.add({
                    "nom": _nomController.text,
                    "motif": _selectedMotif,
                    "dateEntree": dateEntree,
                    "statut": "Présent",
                  });
                  _saveVisiteurs();
                });
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
    setState(() {
      visiteurs.removeAt(index);
      _saveVisiteurs();
    });
  }

  void _marquerCommeParti(int index) {
    final now = DateTime.now();
    final dateDepart =
        "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    setState(() {
      visiteurs[index]['statut'] = 'Parti';
      visiteurs[index]['dateDepart'] = dateDepart;
      _saveVisiteurs();
    });
  }

  void _afficherDetails(Map<String, dynamic> visiteur) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => Scaffold(
          appBar: AppBar(title: Text(visiteur['nom'])),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${getText(context, 'visitor_name')}: ${visiteur['nom']}", style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text("${getText(context, 'reason')}: ${visiteur['motif']}", style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text("Date: ${visiteur['dateEntree']}", style: TextStyle(fontSize: 18)),
                SizedBox(height: 8),
                Text("Statut: ${visiteur['statut']}", style: TextStyle(fontSize: 18)),
                if (visiteur['dateDepart'] != null) ...[
                  SizedBox(height: 8),
                  Text("Date de départ: ${visiteur['dateDepart']}", style: TextStyle(fontSize: 18)),
                ],
              ],
            ),
          ),
        ),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 400),
      ),
    ).then((_) => _loadVisiteurs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(getText(context, 'visitor_list'))),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: getText(context, 'search'),
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
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
                      final nom = visiteur['nom'];
                      if (_searchController.text.isNotEmpty &&
                          !nom.toLowerCase().contains(_searchController.text.toLowerCase())) {
                        return SizedBox.shrink();
                      }
                      return ListTile(
                        title: Text(nom),
                        subtitle: Text("${visiteur['motif']} | ${visiteur['dateEntree']} | ${visiteur['statut']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.logout),
                              tooltip: getText(context, 'mark_as_left'),
                              onPressed: () => _marquerCommeParti(index),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () => _supprimerVisiteur(index),
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
        child: Icon(Icons.add),
        tooltip: getText(context, 'add_visitor'),
      ),
    );
  }
}
