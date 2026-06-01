import 'package:flutter/material.dart';
import '../../../../systeme_conception/couleurs.dart';

class DashboardDoyen extends StatefulWidget {
  const DashboardDoyen({Key? key}) : super(key: key);

  @override
  State<DashboardDoyen> createState() => _DashboardDoyenState();
}

class _DashboardDoyenState extends State<DashboardDoyen> {
  int _ongletActuel = 0; // 0: Vue Globale, 1: Gestion des Roles, 2: Journaux d'Audit

  // Donnees de simulation pour les logs systeme globaux
  final List<Map<String, String>> _journauxAudit = [
    {"temps": "Il y a 2 min", "evenement": "Scan Facial Bulãli ID Reussi", "details": "Prof. Kabasele valide par le CP - L2 Info", "type": "succes"},
    {"temps": "Il y a 15 min", "evenement": "Signalement Retard Enseignant", "details": "Mme Mwamba signalee par le CP - L1 Genie Logiciel", "type": "alerte"},
    {"temps": "Il y a 1 heure", "evenement": "Nouvelle Annonce Publiee", "details": "Appariteur Central : 'Report des examens'", "type": "info"},
    {"temps": "Il y a 2 heures", "evenement": "Fermeture Session de Pointage", "details": "Surveillant Principal - Auditoire 2B", "type": "neutre"},
  ];

  // Donnees des utilisateurs pour la gestion des droits
  final List<Map<String, dynamic>> _utilisateursRoles = [
    {"nom": "Jean-Pierre Kabeya", "role": "Appariteur Central", "faculte": "Sciences Info", "statut": "Actif"},
    {"nom": "Grâce Yambo", "role": "Chef de Promotion", "faculte": "L2 Sciences Info", "statut": "Actif"},
    {"nom": "Anaclet Mwamba", "role": "Surveillant", "faculte": "Polytechnique", "statut": "Actif"},
    {"nom": "Prof. Kabasele", "role": "Enseignant", "faculte": "Sciences Info", "statut": "Actif"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursSmartCampus.fondPrincipal,
      body: Row(
        children: [
          // SIDEBAR DU SUPERADMIN (DOYEN)
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
                        child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Smart Campus',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: CouleursSmartCampus.textePrincipal),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('ESPACE DOYEN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CouleursSmartCampus.texteSecondaire, letterSpacing: 1.2)),
                  ),
                ),
                _construireBoutonSidebar(0, Icons.analytics_rounded, 'Tableau de Bord'),
                _construireBoutonSidebar(1, Icons.security_rounded, 'Gestion des Rôles'),
                _construireBoutonSidebar(2, Icons.receipt_long_rounded, 'Journaux d\'Audit'),
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

          // ZONE DE CONTENU PRINCIPAL
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // EN-TÊTE FIXE DU DOYEN
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Superadministration Évoluée', style: TextStyle(fontSize: 14, color: CouleursSmartCampus.texteSecondaire, fontWeight: FontWeight.w500)),
                          SizedBox(height: 4),
                          Text('Cabinet du Doyen', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: CouleursSmartCampus.textePrincipal)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(color: CouleursSmartCampus.succes.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8, decoration: const BoxDecoration(color: CouleursSmartCampus.succes, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            const Text('Système Bulãli ID : En ligne', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CouleursSmartCampus.succes)),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // CONTENU FILTRÉ SELON L'ONGLET
                  Expanded(child: _chargerVueDoyen())
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _chargerVueDoyen() {
    switch (_ongletActuel) {
      case 0:
        return _construireVueGlobale();
      case 1:
        return _construireVueGestionRoles();
      case 2:
        return _construireVueJournauxAudit();
      default:
        return _construireVueGlobale();
    }
  }

  // 1. VUE TABLEAU DE BORD (MÉTRIQUES GLOBALES)
  Widget _construireVueGlobale() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ligne de cartes analytiques
        Row(
          children: [
            _construireCarteMetrique('94.2%', 'Taux de Présence Global', Icons.trending_up_rounded, CouleursSmartCampus.succes),
            const SizedBox(width: 20),
            _construireCarteMetrique('42', 'Enseignants Actifs Aujourd\'hui', Icons.people_alt_rounded, CouleursSmartCampus.principal),
            const SizedBox(width: 20),
            _construireCarteMetrique('128', 'Séances Validées via CP', Icons.assignment_turned_in_rounded, CouleursSmartCampus.secondaire),
          ],
        ),
        const SizedBox(height: 32),
        
        // Section Double Panneau : Aperçu rapide logs & Alertes critiques
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aperçu rapide des derniers logs (Gauche)
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dernières Activités Campus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _journauxAudit.take(3).length,
                          itemBuilder: (ctx, idx) {
                            final log = _journauxAudit[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.circle, size: 10, color: log['type'] == 'succes' ? CouleursSmartCampus.succes : Colors.orange),
                              title: Text(log['evenement']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: Text(log['details']!, style: const TextStyle(fontSize: 12)),
                              trailing: Text(log['temps']!, style: const TextStyle(fontSize: 11, color: CouleursSmartCampus.texteSecondaire)),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Panneau de Rapports d'anomalies (Droite)
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withOpacity(0.1))),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.warning_amber_rounded, color: Colors.orange),
                          SizedBox(width: 8),
                          Text('Alertes de Retards', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.orange)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Un pic de retard a été signalé aujourd\'hui en Faculté de Polytechnique par les Chefs de Promotion.', style: TextStyle(fontSize: 13, height: 1.4, color: CouleursSmartCampus.texteSecondaire)),
                    ],
                  ),
                ),
              )
            ],
          ),
        )
      ],
    );
  }

  // 2. VUE GESTION DES RÔLES
  Widget _construireVueGestionRoles() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Contrôle d\'Accès des Utilisateurs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Créer un Compte Secrétariat', style: TextStyle(color: Colors.white, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CouleursSmartCampus.principal,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05)))),
                    children: const [
                      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Nom Complet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Rôle assigné', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Attribution', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                      Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Text('Actions Privilèges', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                    ]
                  ),
                  ..._utilisateursRoles.map((user) {
                    return TableRow(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.02)))),
                      children: [
                        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(user['nom'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(user['role'], style: const TextStyle(fontSize: 13))),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(user['faculte'], style: const TextStyle(fontSize: 13, color: CouleursSmartCampus.texteSecondaire))),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              IconButton(icon: const Icon(Icons.shield_outlined, size: 18, color: CouleursSmartCampus.principal), onPressed: () {}),
                              IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {}),
                            ],
                          ),
                        ),
                      ]
                    );
                  }).toList()
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // 3. VUE JOURNAUX D'AUDIT COMPLET
  Widget _construireVueJournauxAudit() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registre d\'Audit Immuable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('Toutes les transactions biométriques Bulãli ID et validations d\'auditoires sont consignées ci-dessous.', style: TextStyle(fontSize: 12, color: CouleursSmartCampus.texteSecondaire)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _journauxAudit.length,
              itemBuilder: (ctx, idx) {
                final log = _journauxAudit[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: CouleursSmartCampus.fondPrincipal, borderRadius: BorderRadius.circular(10)),
                  child: Row(
                    children: [
                      Icon(
                        log['type'] == 'succes' ? Icons.check_circle_outline_rounded : log['type'] == 'alerte' ? Icons.error_outline_rounded : Icons.info_outline_rounded,
                        color: log['type'] == 'succes' ? CouleursSmartCampus.succes : log['type'] == 'alerte' ? Colors.orange : CouleursSmartCampus.texteSecondaire,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log['evenement']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text(log['details']!, style: const TextStyle(fontSize: 12, color: CouleursSmartCampus.texteSecondaire)),
                          ],
                        ),
                      ),
                      Text(log['temps']!, style: const TextStyle(fontSize: 11, color: CouleursSmartCampus.texteSecondaire)),
                    ],
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  // CONSTRUCTEURS D'ÉLÉMENTS GRAPHIQUES
  Widget _construireBoutonSidebar(int index, IconData icone, String titre) {
    bool actif = _ongletActuel == index;
    return InkWell(
      onTap: () => setState(() => _ongletActuel = index),
      child: Container(
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
      ),
    );
  }

  Widget _construireCarteMetrique(String valeur, String label, IconData icone, Color couleurIcone) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(16)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(valeur, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: CouleursSmartCampus.textePrincipal)),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CouleursSmartCampus.texteSecondaire)),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: couleurIcone.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
              child: Icon(icone, color: couleurIcone, size: 24),
            )
          ],
        ),
      ),
    );
  }
}