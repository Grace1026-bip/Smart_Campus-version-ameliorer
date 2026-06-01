import 'package:flutter/material.dart';
import '../../../../systeme_conception/couleurs.dart';

class EcranBulaliId extends StatefulWidget {
  const EcranBulaliId({Key? key}) : super(key: key);

  @override
  State<EcranBulaliId> createState() => _EcranBulaliIdState();
}

class _EcranBulaliIdState extends State<EcranBulaliId> {
  bool _estEnTrainDeScanner = false;
  String _statutScan = "Prêt pour vérification";
  Map<String, String>? _etudiantDetecte;

  void _simulerScanBiometrique() {
    setState(() {
      _estEnTrainDeScanner = true;
      _statutScan = "Analyse des points d'intérêt faciaux...";
      _etudiantDetecte = null;
    });

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _estEnTrainDeScanner = false;
          _statutScan = "Identification réussie ✓";
          _etudiantDetecte = {
            "nom": "Grâce Yambo",
            "matricule": "UPC-2024-GSI3",
            "faculte": "Sciences Informatiques",
            "promotion": "L2 Génie Logiciel",
            "frais": "En règle (100%)",
            "statutAcces": "ACCÈS AUTORISÉ"
          };
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursSmartCampus.fondPrincipal,
      appBar: AppBar(
        backgroundColor: CouleursSmartCampus.fondSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: CouleursSmartCampus.textePrincipal),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Terminal Biométrique Bulãli ID',
          style: TextStyle(color: CouleursSmartCampus.textePrincipal, fontWeight: FontWeight.w700, fontSize: 18),
        ),
        // CORRECTION DE LA BORDURE DE L'APPBAR ICI :
        shape: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05), width: 1)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BLOC GAUCHE : SCANNER
            Expanded(
              flex: 1,
              child: Container(
                height: 550,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: CouleursSmartCampus.principal.withOpacity(0.1), blurRadius: 30, offset: const Offset(0, 10))
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Opacity(
                      opacity: 0.2,
                      child: Icon(Icons.grid_4x4_rounded, size: 400, color: CouleursSmartCampus.principal.withOpacity(0.3)),
                    ),
                    Container(
                      width: 260,
                      height: 340,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _estEnTrainDeScanner ? CouleursSmartCampus.secondaire : CouleursSmartCampus.principal.withOpacity(0.4), 
                          width: 2
                        ),
                        borderRadius: BorderRadius.circular(160),
                      ),
                      child: _estEnTrainDeScanner 
                          ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(CouleursSmartCampus.secondaire)))
                          // CORRECTION DE L'ICÔNE ICI :
                          : Icon(Icons.center_focus_strong_rounded, size: 80, color: Colors.white.withOpacity(0.3)),
                    ),
                    if (_estEnTrainDeScanner)
                      Positioned(
                        top: 150,
                        child: Container(
                          width: 300,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CouleursSmartCampus.secondaire,
                            boxShadow: [
                              BoxShadow(color: CouleursSmartCampus.secondaire, blurRadius: 15, spreadRadius: 3)
                            ]
                          ),
                        ),
                      ),
                    Positioned(
                      bottom: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _estEnTrainDeScanner ? Colors.amber : CouleursSmartCampus.succes,
                                shape: BoxShape.circle
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _statutScan,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 32),

            // BLOC DROITE : FICHE ÉTUDIANT
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: CouleursSmartCampus.fondSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.black.withOpacity(0.04)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Données d\'Authentification',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: CouleursSmartCampus.textePrincipal),
                        ),
                        const SizedBox(height: 24),
                        if (_etudiantDetecte == null)
                          const SizedBox(
                            height: 250,
                            child: Center(
                              child: Text(
                                'En attente d\'un scan facial...',
                                style: TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 14),
                              ),
                            ),
                          )
                        else ...[
                          _construireChampInfo('Nom complet', _etudiantDetecte!['nom']!),
                          _construireChampInfo('Numéro Matricule', _etudiantDetecte!['matricule']!),
                          _construireChampInfo('Faculté', _etudiantDetecte!['faculte']!),
                          _construireChampInfo('Promotion', _etudiantDetecte!['promotion']!),
                          _construireChampInfo('État des Frais', _etudiantDetecte!['frais']!, couleurValeur: CouleursSmartCampus.succes),
                          const Divider(height: 32),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CouleursSmartCampus.succes.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                _etudiantDetecte!['statutAcces']!,
                                style: const TextStyle(color: CouleursSmartCampus.succes, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1.5),
                              ),
                            ),
                          )
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _estEnTrainDeScanner ? null : _simulerScanBiometrique,
                      icon: const Icon(Icons.face_unlock_rounded, size: 22),
                      label: const Text(
                        'Simuler une détection faciale',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: CouleursSmartCampus.principal,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _construireChampInfo(String label, String valeur, {Color? couleurValeur}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 14, fontWeight: FontWeight.w500)),
          Text(valeur, style: TextStyle(color: couleurValeur ?? CouleursSmartCampus.textePrincipal, fontSize: 14, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}