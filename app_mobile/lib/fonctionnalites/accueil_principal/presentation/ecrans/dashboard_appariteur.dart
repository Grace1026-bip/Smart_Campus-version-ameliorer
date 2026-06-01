import 'package:flutter/material.dart';
import '../../../../systeme_conception/couleurs.dart';

class DashboardAppariteur extends StatefulWidget {
  const DashboardAppariteur({Key? key}) : super(key: key);

  @override
  State<DashboardAppariteur> createState() => _DashboardAppariteurState();
}

class _DashboardAppariteurState extends State<DashboardAppariteur> {
  int _ongletPrincipal = 0; // 0: Rapports Etudiants, 1: Suivi Professeurs, 2: Hub Communications, 3: IA Decisionnelle
  int _canalChatSelectionne = 0; // 0: Diffusion a tous les CP, 1: Chat Prive CP, 2: Chat Prive Profs

  // 1. DOCK DES ALERTES DE RETARDS ENVOYÉES PAR LES CP (TEMPS RÉEL)
  final List<Map<String, String>> _alertesCP = [
    {"cp": "Grâce Yambo", "promo": "L2 Sciences Info", "prof": "Prof. Kabasele", "cours": "Génie Logiciel", "heure": "Il y a 2 min"},
    {"cp": "Félix Tshituka", "promo": "L1 Génie Logiciel", "prof": "Mme Mwamba", "cours": "Bases de Données", "heure": "Il y a 14 min"},
  ];

  // 2. DATA ÉTUDIANTS : CHAQUE PROMOTION + GLOBAL
  final List<Map<String, dynamic>> _promotionsData = [
    {"nom": "L1 Génie Logiciel", "effectif": 120, "taux": 88.5, "statut": "Stable"},
    {"nom": "L2 Sciences Info", "effectif": 95, "taux": 92.4, "statut": "Excellent"},
    {"nom": "L3 Admin Réseau", "effectif": 73, "taux": 74.1, "statut": "Vigilance"},
    {"nom": "M1 Cybersécurité", "effectif": 45, "taux": 96.8, "statut": "Excellent"},
  ];

  // 3. DATA PROFESSEURS : ASSIDUITÉ NOMINATIVE DE CHACUN
  final List<Map<String, dynamic>> _professeursData = [
    {"nom": "Prof. Kabasele", "chaire": "Génie Logiciel Avancé", "taux": 84.5, "coursDonnes": "22h / 26h"},
    {"nom": "Mme. Mwamba", "chaire": "Systèmes de Gestion de BD", "taux": 100.0, "coursDonnes": "30h / 30h"},
    {"nom": "Prof. Tshimanga", "chaire": "Algorithmique & Complexité", "taux": 91.2, "coursDonnes": "18h / 20h"},
    {"nom": "Dr. Ilunga", "chaire": "Électricité Générale", "taux": 78.0, "coursDonnes": "14h / 18h"},
  ];

  // 4. HISTORIQUE IA ANALYTICS
  final List<Map<String, dynamic>> _conversationsIA = [
    {
      "role": "ia", 
      "message": "Bonjour Monsieur l'Appariteur. Je suis configurée sur le modèle Bulãli Analytics. Prête à compiler vos registres de présence, auditer les heures des professeurs ou générer vos rapports de synthèse."
    }
  ];

  final TextEditingController _textController = TextEditingController();

  // Calcul automatique du taux de présence combiné de tous les étudiants
  double get _tauxMoyenGlobalEtudiants {
    double somme = 0;
    for (var promo in _promotionsData) {
      somme += promo['taux'];
    }
    return somme / _promotionsData.length;
  }

  void _executerRequeteIA(String requete) {
    if (requete.trim().isEmpty) return;
    setState(() {
      _conversationsIA.add({"role": "user", "message": _textController.text});
      _textController.clear();
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      setState(() {
        String reqClair = requete.toLowerCase();
        if (reqClair.contains("rapport") || reqClair.contains("analyse")) {
          _conversationsIA.add({
            "role": "ia",
            "message": "📊 **Rapport d'Analyse Synthétique :**\n\n1. **Décrochage ciblé** : La promotion *L3 Admin Réseau* est passée sous le seuil critique avec **74.1%** de présence moyenne.\n2. **Performance Enseignants** : Mme Mwamba maintient un taux parfait de **100%** sur ses 30 heures programmées.\n3. **Alerte RH** : Dr. Ilunga est à surveiller (taux d'assiduité de **78%**)."
          });
        } else if (reqClair.contains("retard") || reqClair.contains("cp")) {
          _conversationsIA.add({
            "role": "ia",
            "message": "⚠️ **Analyse des incidents de ponctualité :**\n\nCe matin, deux retards ont été enregistrés via Bulãli ID par les Chefs de Promotion. Le cours de Génie Logiciel accumule un déficit cumulé de 45 minutes ce mois-ci."
          });
        } else {
          _conversationsIA.add({
            "role": "ia",
            "message": "J'ai analysé la base de données courante. Tout est consigné dans vos registres de présence. Que souhaitez-vous auditer d'autre ?"
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursSmartCampus.fondPrincipal,
      body: Row(
        children: [
          // =========================================================================
          // SIDEBAR DE NAVIGATION PRINCIPALE
          // =========================================================================
          Container(
            width: 270,
            decoration: BoxDecoration(
              color: CouleursSmartCampus.fondSurface,
              border: Border(right: BorderSide(color: Colors.black.withOpacity(0.05))),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(color: CouleursSmartCampus.principal, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Text('Smart Campus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: CouleursSmartCampus.textePrincipal)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Align(alignment: Alignment.centerLeft, child: Text('TOUR DE CONTRÔLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: CouleursSmartCampus.texteSecondaire, letterSpacing: 1.2))),
                ),
                _construireItemSidebar(0, Icons.groups_rounded, 'Présence Étudiants'),
                _construireItemSidebar(1, Icons.badge_rounded, 'Suivi des Professeurs'),
                _construireItemSidebar(2, Icons.quickreply_rounded, 'Hub Communications'),
                _construireItemSidebar(3, Icons.analytics_rounded, 'IA Décisionnelle'),
                const Spacer(),
                // Déconnexion
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

          // =========================================================================
          // CONTENU DYNAMIQUE DE L'APPARITEUR
          // =========================================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // EN-TÊTE DE SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Services Académiques Centraux', style: TextStyle(fontSize: 13, color: CouleursSmartCampus.texteSecondaire, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(_obtenirTitreOnglet(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: CouleursSmartCampus.textePrincipal)),
                        ],
                      ),
                      // Indicateur d'état du système
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: CouleursSmartCampus.principal.withOpacity(0.06), borderRadius: BorderRadius.circular(8)),
                        child: const Text('Mode : Supervision Globale', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: CouleursSmartCampus.principal)),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // FIL D'ALERTES DE RETARD DES CP (VISIBLE EN PERMANENCE SUR LES ONGLETS DE SUIVI)
                  if (_ongletPrincipal == 0 || _ongletPrincipal == 1) _construireBarreAlertesRetard(),

                  const SizedBox(height: 16),
                  Expanded(child: _chargerContenuPrincipal())
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Changer le contenu selon l'onglet choisi
  Widget _chargerContenuPrincipal() {
    switch (_ongletPrincipal) {
      case 0:
        return _construireVueEtudiants();
      case 1:
        return _construireVueProfesseurs();
      case 2:
        return _construireVueCommunications();
      case 3:
        return _construireVueIA();
      default:
        return _construireVueEtudiants();
    }
  }

  String _obtenirTitreOnglet() {
    List<String> titres = [
      "Registre de Présence Étudiants",
      "Assiduité Nominative Enseignants",
      "Centre de Communication Stratégique",
      "Analyseur IA & Synthèse de Données"
    ];
    return titres[_ongletPrincipal];
  }

  // =========================================================================
  // BLOC COMPOSANT : FLUX DES ALERTES DE RETARD DES CP
  // =========================================================================
  Widget _construireBarreAlertesRetard() {
    if (_alertesCP.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Text('Alertes de retards signalées en direct par les CP', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.orange, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: _alertesCP.map((alt) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 13, color: CouleursSmartCampus.textePrincipal),
                      children: [
                        TextSpan(text: "${alt['cp']} (${alt['promo']}) : ", style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: "${alt['prof']} n'est pas encore arrivé pour le cours de "),
                        TextSpan(text: "${alt['cours']}.", style: const TextStyle(fontWeight: FontWeight.w600, color: CouleursSmartCampus.principal)),
                      ]
                    ),
                  ),
                  Text(alt['heure']!, style: const TextStyle(fontSize: 11, color: CouleursSmartCampus.texteSecondaire, fontWeight: FontWeight.w600)),
                ],
              ),
            )).toList(),
          )
        ],
      ),
    );
  }

  // =========================================================================
  // VUE 1 : RAPPORTS ET POURCENTAGES DES ÉTUDIANTS
  // =========================================================================
  Widget _construireVueEtudiants() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte maîtresse : Taux général combiné de TOUS les étudiants
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [CouleursSmartCampus.principal, CouleursSmartCampus.secondaire]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Moyenne Générale de Présence Inter-Promotions', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Text('${_tauxMoyenGlobalEtudiants.toStringAsFixed(1)} %', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                ],
              ),
              const Icon(Icons.analytics, color: Colors.white30, size: 48),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text('Pourcentage Moyen de Présence de Chaque Promotion', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        // Grille ou Table détaillée par promotion
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(16)),
            child: ListView(
              children: [
                Table(
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
                        Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Promotion', style: TextStyle(fontWeight: FontWeight.w700))),
                        Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Effectif Assujetti', style: TextStyle(fontWeight: FontWeight.w700))),
                        Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Taux d\'Assiduité', style: TextStyle(fontWeight: FontWeight.w700))),
                        Padding(padding: EdgeInsets.only(bottom: 12), child: Text('Avis Système', style: TextStyle(fontWeight: FontWeight.w700))),
                      ]
                    ),
                    ..._promotionsData.map((promo) => TableRow(
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.01)))),
                      children: [
                        Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text(promo['nom'], style: const TextStyle(fontWeight: FontWeight.w600))),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text('${promo['effectif']} étudiants')),
                        Padding(padding: const EdgeInsets.symmetric(vertical: 14), child: Text('${promo['taux']} %', style: TextStyle(fontWeight: FontWeight.w800, color: promo['taux'] < 80 ? CouleursSmartCampus.erreur : CouleursSmartCampus.succes))),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Text(promo['statut'], style: TextStyle(fontWeight: FontWeight.w600, color: promo['statut'] == 'Vigilance' ? Colors.orange : CouleursSmartCampus.texteSecondaire)),
                        ),
                      ]
                    )).toList()
                  ],
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  // =========================================================================
  // VUE 2 : TAUX DE PRÉSENCE DE CHAQUE PROFESSEUR
  // =========================================================================
  Widget _construireVueProfesseurs() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Registre d\'Émargement Biométrique Nominatif (Enseignants)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 2.5),
              itemCount: _professeursData.length,
              itemBuilder: (context, idx) {
                final prof = _professeursData[idx];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CouleursSmartCampus.fondPrincipal,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black.withOpacity(0.02)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: CouleursSmartCampus.principal.withOpacity(0.1),
                        child: Text(prof['nom'][5], style: const TextStyle(fontWeight: FontWeight.bold, color: CouleursSmartCampus.principal)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(prof['nom'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(prof['chaire'], style: const TextStyle(fontSize: 11, color: CouleursSmartCampus.texteSecondaire), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Text("Prestation : ${prof['coursDonnes']}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${prof['taux']}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: CouleursSmartCampus.principal)),
                          const Text('Présence', style: TextStyle(fontSize: 9, color: CouleursSmartCampus.texteSecondaire)),
                        ],
                      )
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

  // =========================================================================
  // VUE 3 : HUB COMMUNICATIONS TRI-CANAL
  // =========================================================================
  Widget _construireVueCommunications() {
    return Row(
      children: [
        // Sélecteur interne de canaux
        Container(
          width: 240,
          decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              _construireBoutonCanal(0, Icons.campaign, "Diffusion Globale CP"),
              _construireBoutonCanal(1, Icons.assignment_ind_rounded, "Messages Privés CP"),
              _construireBoutonCanal(2, Icons.supervisor_account_rounded, "Messages Privés Profs"),
            ],
          ),
        ),
        const SizedBox(width: 24),

        // Zone d'action de messagerie active
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(16)),
            child: _chargerCanalDeChatFiltre(),
          ),
        )
      ],
    );
  }

  Widget _chargerCanalDeChatFiltre() {
    if (_canalChatSelectionne == 0) {
      // CANAL DE MASSE : DIFFUSION À TOUS LES CP
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Publier un Communiqué Universel (Destiné à TOUS les Chefs de Promotion)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 6),
          const Text('Ce message sera instantanément épinglé en tête du flux de tous les CP du campus.', style: TextStyle(fontSize: 12, color: CouleursSmartCampus.texteSecondaire)),
          const SizedBox(height: 20),
          Expanded(
            child: TextField(
              maxLines: 8,
              decoration: InputDecoration(
                hintText: 'Exemple : "Avis à tous les CP, la séance académique de ce vendredi est décalée à l\'Auditoire Central..."',
                filled: true,
                fillColor: CouleursSmartCampus.fondPrincipal,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Communiqué diffusé à l\'ensemble des Chefs de Promotion ✓')));
              },
              icon: const Icon(Icons.send, color: Colors.white, size: 16),
              label: const Text('Lancer la diffusion', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: CouleursSmartCampus.principal, minimumSize: const Size(180, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            ),
          )
        ],
      );
    } else {
      // DISCUSSIONS PRIVÉES INDIVIDUELLES (CP OU PROFS)
      String cibleType = _canalChatSelectionne == 1 ? "Chef de Promotion" : "Professeur";
      return Column(
        children: [
          Align(alignment: Alignment.centerLeft, child: Text('Fils de discussions privées : $cibleType', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14))),
          const Divider(height: 24),
          Expanded(
            child: ListView(
              children: [
                _construireItemChatIndividuel(_canalChatSelectionne == 1 ? "Grâce Yambo (CP L2 Sciences Info)" : "Prof. Kabasele", "Bien reçu Monsieur l'Appariteur, je transmets."),
                _construireItemChatIndividuel(_canalChatSelectionne == 1 ? "Félix Tshituka (CP L1 GL)" : "Mme. Mwamba", "Les émargements Bulãli ID de ce matin sont clos."),
              ],
            ),
          ),
          TextField(
            decoration: InputDecoration(
              hintText: 'Rédiger une réponse privée individuelle...',
              suffixIcon: const Icon(Icons.send, color: CouleursSmartCampus.principal),
              filled: true,
              fillColor: CouleursSmartCampus.fondPrincipal,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          )
        ],
      );
    }
  }

  // =========================================================================
  // VUE 4 : IA DÉCISIONNELLE DÉDIÉE AUX RAPPORTS ET ANALYSES
  // =========================================================================
  Widget _construireVueIA() {
    return Column(
      children: [
        // En-tête IA
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: CouleursSmartCampus.principal.withOpacity(0.04), borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: const [
              Icon(Icons.psychology_rounded, color: CouleursSmartCampus.principal, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Moteur Core Analytics Bulãli ID', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text('Modèle IA configuré exclusivement pour auditer l\'assiduité, croiser les volumes horaires et extraire des tendances.', style: TextStyle(fontSize: 11, color: CouleursSmartCampus.texteSecondaire)),
                  ],
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Raccourcis d'analyses rapides (Triggers)
        Row(
          children: [
            _construireBoutonTriggerIA("📊 Compiler Rapport Mensuel"),
            const SizedBox(width: 12),
            _construireBoutonTriggerIA("⚠️ Détecter Décrochages Promos"),
            const SizedBox(width: 12),
            _construireBoutonTriggerIA("👨‍🏫 Auditer Retards Profs"),
          ],
        ),
        const SizedBox(height: 16),

        // Zone d'affichage conversationnelle
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(16)),
            child: ListView.builder(
              itemCount: _conversationsIA.length,
              itemBuilder: (ctx, idx) {
                var messageNode = _conversationsIA[idx];
                bool estIA = messageNode['role'] == 'ia';
                return Align(
                  alignment: estIA ? Alignment.centerLeft : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: estIA ? CouleursSmartCampus.fondPrincipal : CouleursSmartCampus.principal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      messageNode['message'],
                      style: TextStyle(fontSize: 13, color: estIA ? CouleursSmartCampus.textePrincipal : Colors.white, height: 1.4),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Input barre d'analyse
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                onSubmitted: _executerRequeteIA,
                decoration: InputDecoration(
                  hintText: 'Demander une analyse statistique sur les promotions ou profs...',
                  filled: true,
                  fillColor: CouleursSmartCampus.fondSurface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: CouleursSmartCampus.principal),
              onPressed: () => _executerRequeteIA(_textController.text),
            )
          ],
        )
      ],
    );
  }

  // =========================================================================
  // BOUTONS COMPOSANTS SECONDAIRES & UTILS (STRICT ASCII IDENTIFIERS)
  // =========================================================================
  Widget _construireItemSidebar(int index, IconData icone, String titre) {
    bool actif = _ongletPrincipal == index;
    return InkWell(
      onTap: () => setState(() => _ongletPrincipal = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: actif ? CouleursSmartCampus.principal.withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
        child: Row(
          children: [
            Icon(icone, color: actif ? CouleursSmartCampus.principal : CouleursSmartCampus.texteSecondaire, size: 20),
            const SizedBox(width: 16),
            Text(titre, style: TextStyle(fontSize: 14, fontWeight: actif ? FontWeight.w700 : FontWeight.w500, color: actif ? CouleursSmartCampus.principal : CouleursSmartCampus.textePrincipal)),
          ],
        ),
      ),
    );
  }

  Widget _construireBoutonCanal(int index, IconData icone, String titre) {
    bool actif = _canalChatSelectionne == index;
    return InkWell(
      onTap: () => setState(() => _canalChatSelectionne = index),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: actif ? CouleursSmartCampus.fondPrincipal : Colors.transparent, borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Icon(icone, size: 18, color: actif ? CouleursSmartCampus.principal : CouleursSmartCampus.texteSecondaire),
            const SizedBox(width: 12),
            Expanded(child: Text(titre, style: TextStyle(fontSize: 12, fontWeight: actif ? FontWeight.w700 : FontWeight.w500))),
          ],
        ),
      ),
    );
  }

  Widget _construireBoutonTriggerIA(String label) {
    return InkWell(
      onTap: () {
        _textController.text = label.substring(2); // extrait l'emoji
        _executerRequeteIA(_textController.text);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.03))),
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _construireItemChatIndividuel(String correspondant, String dernierMessage) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(backgroundColor: CouleursSmartCampus.fondPrincipal, child: const Icon(Icons.person, size: 16)),
      title: Text(correspondant, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      subtitle: Text(dernierMessage, style: const TextStyle(fontSize: 12, color: CouleursSmartCampus.texteSecondaire), maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, size: 14),
    );
  }
}