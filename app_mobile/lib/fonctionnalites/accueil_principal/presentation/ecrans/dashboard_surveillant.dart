import 'package:flutter/material.dart';
import '../../../../systeme_conception/couleurs.dart';

class DashboardSurveillant extends StatefulWidget {
  const DashboardSurveillant({Key? key}) : super(key: key);

  @override
  State<DashboardSurveillant> createState() => _DashboardSurveillantState();
}

class _DashboardSurveillantState extends State<DashboardSurveillant> {
  bool _estEnTrainDeScanner = false;
  String _messageScan = "Placer le visage devant la caméra";

  // Base de données locale factice contenant des scans de dates différentes
  final List<Map<String, dynamic>> _tousLesScansDuSysteme = [
    {
      "nom": "Kambale Christian",
      "promotion": "G2 GSI",
      "heure": "08:14",
      "date": DateTime.now(), // Aujourd'hui -> Sera affiché
      "statut": "Autorisé",
      "couleur": CouleursSmartCampus.succes
    },
    {
      "nom": "Mbuyi Sarah",
      "promotion": "G3 MSI",
      "heure": "08:30",
      "date": DateTime.now(), // Aujourd'hui -> Sera affiché
      "statut": "Autorisé",
      "couleur": CouleursSmartCampus.succes
    },
    {
      "nom": "Kasongo Prince",
      "promotion": "L1 CS",
      "heure": "16:45",
      "date": DateTime.now().subtract(const Duration(days: 1)), // Hier -> Sera masqué !
      "statut": "Autorisé",
      "couleur": CouleursSmartCampus.succes
    },
  ];

  // Fonction pour vérifier si une date correspond à aujourd'hui
  bool _estAujourdHui(DateTime date) {
    final maintenant = DateTime.now();
    return date.year == maintenant.year &&
        date.month == maintenant.month &&
        date.day == maintenant.day;
  }

  void _declencherScan() {
    setState(() {
      _estEnTrainDeScanner = true;
      _messageScan = "Analyse faciale Bulãli ID en cours...";
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _estEnTrainDeScanner = false;
          _messageScan = "Scan réussi ✓";
          
          // On ajoute le nouveau scan avec la date précise d'aujourd'hui
          _tousLesScansDuSysteme.insert(0, {
            "nom": "Kakule Joseph",
            "promotion": "L2 Génie Logiciel",
            "heure": "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}",
            "date": DateTime.now(),
            "statut": "Autorisé",
            "couleur": CouleursSmartCampus.succes
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // FILTRE MAGIQUE : On extrait uniquement les scans dont la date est égale à AUJOURD'HUI
    final scansDuJour = _tousLesScansDuSysteme.where((scan) => _estAujourdHui(scan['date'])).toList();

    return Scaffold(
      backgroundColor: CouleursSmartCampus.fondPrincipal,
      body: Row(
        children: [
          // SIDEBAR SURVEILLANT (Version ultra-simplifiée en lecture seule)
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: CouleursSmartCampus.fondSurface,
              border: Border(right: BorderSide(color: Colors.black.withOpacity(0.05), width: 1)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        height: 32,
                        width: 32,
                        decoration: BoxDecoration(
                          color: CouleursSmartCampus.secondaire,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.security_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Smart Campus',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: CouleursSmartCampus.textePrincipal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Un seul onglet disponible pour lui
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: CouleursSmartCampus.secondaire.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.face_unlock_rounded, color: CouleursSmartCampus.secondaire, size: 20),
                      const SizedBox(width: 16),
                      Text('Point de Contrôle', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CouleursSmartCampus.secondaire)),
                    ],
                  ),
                ),
                const Spacer(),
                // Bouton Déconnexion
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: const [
                        Icon(Icons.logout_rounded, color: CouleursSmartCampus.erreur, size: 20),
                        SizedBox(width: 16),
                        Text('Déconnexion', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: CouleursSmartCampus.erreur)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // CONTENU DE VÉRIFICATION
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ZONE DE SCAN (GAUCHE)
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: CouleursSmartCampus.fondSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withOpacity(0.03)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Scanner d\'Entrée',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: CouleursSmartCampus.textePrincipal),
                          ),
                          const SizedBox(height: 40),
                          Container(
                            height: 240,
                            width: 240,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.02),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _estEnTrainDeScanner ? CouleursSmartCampus.secondaire : CouleursSmartCampus.texteSecondaire.withOpacity(0.2),
                                width: 3,
                              ),
                            ),
                            child: Center(
                              child: _estEnTrainDeScanner
                                  ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(CouleursSmartCampus.secondaire))
                                  : Icon(Icons.center_focus_strong_rounded, size: 64, color: CouleursSmartCampus.texteSecondaire.withOpacity(0.5)),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            _messageScan,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: CouleursSmartCampus.texteSecondaire),
                          ),
                          const SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton.icon(
                              onPressed: _estEnTrainDeScanner ? null : _declencherScan,
                              icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                              label: const Text('Déclencher la caméra Bulãli ID'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CouleursSmartCampus.secondaire,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 32),

                  // HISTORIQUE JOURNALIER AUTOMATIQUE (DROITE)
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: CouleursSmartCampus.fondSurface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.black.withOpacity(0.03)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Flux Historique Journalier',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: CouleursSmartCampus.textePrincipal),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Aujourd\'hui uniquement',
                                  style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Cet historique se vide automatiquement chaque minuit pour des raisons de confidentialité.',
                            style: TextStyle(fontSize: 12, color: CouleursSmartCampus.texteSecondaire),
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: scansDuJour.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Aucun scan enregistré aujourd\'hui.',
                                      style: TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 13),
                                    ),
                                  )
                                : ListView.builder(
                                    itemCount: scansDuJour.length,
                                    itemBuilder: (context, index) {
                                      final item = scansDuJour[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: CouleursSmartCampus.fondPrincipal.withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(item['nom']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: CouleursSmartCampus.textePrincipal)),
                                                const SizedBox(height: 4),
                                                Text('${item['promotion']} • À ${item['heure']}', style: const TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 12)),
                                              ],
                                            ),
                                            Text(
                                              item['statut']!,
                                              style: TextStyle(color: item['couleur'] as Color, fontWeight: FontWeight.w700, fontSize: 13),
                                            )
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}