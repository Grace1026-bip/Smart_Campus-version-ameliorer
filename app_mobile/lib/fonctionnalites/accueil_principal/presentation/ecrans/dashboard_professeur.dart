import 'package:flutter/material.dart';
import '../../../../systeme_conception/couleurs.dart';

class DashboardProfesseur extends StatefulWidget {
  const DashboardProfesseur({Key? key}) : super(key: key);

  @override
  State<DashboardProfesseur> createState() => _DashboardProfesseurState();
}

class _DashboardProfesseurState extends State<DashboardProfesseur> {
  bool _estEnTrainDeValider = false;
  bool _presenceValidee = false;
  
  // Suivi des heures et salaire
  int _heuresPresteesCeMois = 28;
  final double _tauxHoraire = 45.0;

  // Fonction de simulation (déclenchée fictivement par le Chef de Promotion)
  void _simulerValidationDuChefDePromo() {
    setState(() {
      _estEnTrainDeValider = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _estEnTrainDeValider = false;
          _presenceValidee = true;
          _heuresPresteesCeMois += 2; 
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double salaireEstime = _heuresPresteesCeMois * _tauxHoraire;

    return Scaffold(
      backgroundColor: CouleursSmartCampus.fondPrincipal,
      body: Row(
        children: [
          // SIDEBAR PROFESSEUR
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
                          color: CouleursSmartCampus.principal,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 16),
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
                _construireElementSidebar(Icons.school_rounded, 'Mon Espace Cours', actif: true),
                _construireElementSidebar(Icons.history_toggle_off_rounded, 'Historique des Heures'),
                _construireElementSidebar(Icons.payments_outlined, 'Rémunération'),
                const Spacer(),
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

          // CONTENU CENTRAL
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // EN-TÊTE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Espace Enseignant', style: TextStyle(fontSize: 14, color: CouleursSmartCampus.texteSecondaire, fontWeight: FontWeight.w500)),
                          SizedBox(height: 4),
                          Text('Ravi de vous revoir, Professeur', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: CouleursSmartCampus.textePrincipal)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: CouleursSmartCampus.principal.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, color: CouleursSmartCampus.principal, size: 18),
                            const SizedBox(width: 10),
                            Text(
                              'Salaire Estimé : $salaireEstime \$',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: CouleursSmartCampus.principal, fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),

                  // PRÉSENCE & RELEVÉ HORAIRE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // BLOC STATUT DE PRÉSENCE (MODIFIÉ : LECTURE SEULE)
                      Expanded(
                        flex: 4,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: CouleursSmartCampus.fondSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.black.withOpacity(0.03)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Statut de la Séance Actuelle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              const Text('La validation biométrique Bulãli ID s\'effectue auprès du Chef de Promotion en classe.', style: TextStyle(fontSize: 13, color: CouleursSmartCampus.texteSecondaire)),
                              const SizedBox(height: 24),
                              
                              if (!_presenceValidee) ...[
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.amber.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      _estEnTrainDeValider 
                                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.amber)))
                                          : const Icon(Icons.pending_actions_rounded, color: Colors.amber, size: 28),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(_estEnTrainDeValider ? 'Analyse faciale en cours...' : 'En attente du Chef de Promotion', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.amber, fontSize: 14)),
                                            const SizedBox(height: 2),
                                            const Text('Veuillez vous présenter devant l\'appareil du CP pour ouvrir la séance.', style: TextStyle(fontSize: 12, color: CouleursSmartCampus.texteSecondaire)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                // BOUTON DE TEST TEMPORAIRE (Pour simuler le CP)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: _estEnTrainDeValider ? null : _simulerValidationDuChefDePromo,
                                    icon: const Icon(Icons.bolt, size: 16, color: CouleursSmartCampus.texteSecondaire),
                                    label: const Text('[Démo] Simuler le scan du CP', style: TextStyle(fontSize: 12, color: CouleursSmartCampus.texteSecondaire)),
                                  ),
                                )
                              ] else ...[
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(color: CouleursSmartCampus.succes.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: CouleursSmartCampus.succes, size: 28),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text('Séance Confirmée par le CP ✓', style: TextStyle(fontWeight: FontWeight.w700, color: CouleursSmartCampus.succes, fontSize: 15)),
                                          SizedBox(height: 2),
                                          Text('Présence enregistrée. +2 heures créditées avec succès.', style: TextStyle(fontSize: 12, color: CouleursSmartCampus.texteSecondaire)),
                                        ],
                                      )
                                    ],
                                  ),
                                )
                              ]
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // COMPTEUR HORAIRE
                      Expanded(
                        flex: 3,
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          height: 250,
                          decoration: BoxDecoration(
                            color: CouleursSmartCampus.fondSurface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.black.withOpacity(0.03)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Compteur de Prestation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$_heuresPresteesCeMois h', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: CouleursSmartCampus.principal)),
                                  const Text('Effectuées ce mois-ci', style: TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 13, fontWeight: FontWeight.w500)),
                                ],
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Taux horaire :', style: TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 13)),
                                  Text('$_tauxHoraire \$ / h', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                ],
                              )
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),

                  // PROGRAMME DU JOUR
                  const Text('Mon programme du jour', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  _construireCarteCours('08:00 - 10:00', 'Architecture des Ordinateurs', 'L1 Génie Logiciel', 'Auditoire 2B', termine: true),
                  _construireCarteCours('10:30 - 12:30', 'Génie Logiciel Avancé', 'L2 Sciences Informatiques', 'Laboratoire Info', actif: !_presenceValidee),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _construireElementSidebar(IconData icone, String titre, {bool actif = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: actif ? CouleursSmartCampus.principal.withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icone, color: actif ? CouleursSmartCampus.principal : CouleursSmartCampus.texteSecondaire, size: 20),
          const SizedBox(width: 16),
          Text(titre, style: TextStyle(fontSize: 14, fontWeight: actif ? FontWeight.w600 : FontWeight.w500, color: actif ? CouleursSmartCampus.principal : CouleursSmartCampus.textePrincipal)),
        ],
      ),
    );
  }

  Widget _construireCarteCours(String heure, String cours, String classe, String local, {bool termine = false, bool actif = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CouleursSmartCampus.fondSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: actif ? CouleursSmartCampus.principal.withOpacity(0.3) : Colors.black.withOpacity(0.02)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: CouleursSmartCampus.fondPrincipal, borderRadius: BorderRadius.circular(8)),
                child: Text(heure, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: CouleursSmartCampus.texteSecondaire)),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cours, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: termine ? CouleursSmartCampus.texteSecondaire : CouleursSmartCampus.textePrincipal, decoration: termine ? TextDecoration.lineThrough : null)),
                  const SizedBox(height: 4),
                  Text('$classe • $local', style: const TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 12)),
                ],
              ),
            ],
          ),
          if (termine)
            const Icon(Icons.check_circle_rounded, color: CouleursSmartCampus.succes, size: 20)
          else if (actif)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: const Text('En cours', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600)),
            )
        ],
      ),
    );
  }
}