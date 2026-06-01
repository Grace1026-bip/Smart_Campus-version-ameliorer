import 'package:flutter/material.dart';
import '../../../../systeme_conception/couleurs.dart';

class DashboardChefPromotion extends StatefulWidget {
  const DashboardChefPromotion({Key? key}) : super(key: key);

  @override
  State<DashboardChefPromotion> createState() => _DashboardChefPromotionState();
}

class _DashboardChefPromotionState extends State<DashboardChefPromotion> {
  int _ongletActuel = 0; // 0: Pointage, 1: Canal Appariteur, 2: Messages Profs
  
  // États pour les simulations biométriques
  String _statutAction = "En attente d'une action";
  bool _enCoursDeTraitement = false;
  String _profSelectionne = "Prof. Kabasele (Génie Logiciel)";

  // Données factices pour les flux de discussion
  final List<Map<String, String>> _annoncesAppariteur = [
    {"titre": "Report de la session d'examens", "contenu": "La session initialement prévue ce lundi est décalée de 48 heures.", "date": "Aujourd'hui, 09:12"},
    {"titre": "Maintenance des Labos", "contenu": "Le laboratoire d'informatique sera fermé ce jeudi pour déploiement réseau.", "date": "Hier, 14:30"}
  ];

  final List<Map<String, String>> _messagesProfs = [
    {"prof": "Prof. Kabasele", "dernierMessage": "Je serai en retard de 15 minutes pour le cours de Génie Logiciel.", "heure": "09:45"},
    {"prof": "Mme. Mwamba", "dernierMessage": "N'oubliez pas de collecter les TP de Base de Données aujourd'hui.", "heure": "Hier"}
  ];

  void _declencherBiometrie(String type) {
    setState(() {
      _enCoursDeTraitement = true;
      _statutAction = "Authentification $type en cours via Bulãli ID...";
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _enCoursDeTraitement = false;
          _statutAction = "Succès : Présence validée pour $_profSelectionne via $type ✓";
        });
      }
    });
  }

  void _signalerRetard() {
    setState(() {
      _statutAction = "Retard signalé à l'Apparition pour $_profSelectionne ⚠️";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CouleursSmartCampus.fondPrincipal,
      body: Row(
        children: [
          // SIDEBAR DU CHEF DE PROMOTION
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
                        child: const Icon(Icons.stars_rounded, color: Colors.white, size: 16),
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
                _construireBoutonSidebar(0, Icons.fact_check_rounded, 'Pointage Enseignants'),
                _construireBoutonSidebar(1, Icons.campaign_rounded, 'Canal Appariteur'),
                _construireBoutonSidebar(2, Icons.forum_rounded, 'Messagerie Profs'),
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

          // CONTENU DYNAMIQUE SELON L'ONGLET SÉLECTIONNÉ
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: _chargerVueOnglet(),
            ),
          )
        ],
      ),
    );
  }

  // Sélecteur de vue
  Widget _chargerVueOnglet() {
    switch (_ongletActuel) {
      case 0:
        return _construireVuePointage();
      case 1:
        return _construireVueAppariteur();
      case 2:
        return _construireVueMessagerieProfs();
      default:
        return _construireVuePointage();
    }
  }

  // 1. VUE POINTAGE ET SUIVI ENSEIGNANTS
  Widget _construireVuePointage() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Panneau des commandes biométriques
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Terminal de Validation Enseignant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                const Text('Sélectionnez le professeur actuellement présent dans votre auditoire pour enregistrer sa présence.', style: TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 13)),
                const SizedBox(height: 32),
                
                // Sélection du prof
                const Text('Professeur à auditer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: CouleursSmartCampus.fondPrincipal, borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _profSelectionne,
                      isExpanded: true,
                      items: <String>["Prof. Kabasele (Génie Logiciel)", "Mme. Mwamba (Base de Données)", "Prof. Tshimanga (Algorithmique)"]
                          .map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                      onChanged: (val) { if (val != null) setState(() => _profSelectionne = val); },
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Statut de l'action en temps réel
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statutAction.contains("Succès") ? CouleursSmartCampus.succes.withOpacity(0.08) : _statutAction.contains("retard") ? Colors.orange.withOpacity(0.08) : CouleursSmartCampus.fondPrincipal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_statutAction, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _statutAction.contains("Succès") ? CouleursSmartCampus.succes : _statutAction.contains("retard") ? Colors.orange : CouleursSmartCampus.texteSecondaire)),
                ),
                const SizedBox(height: 40),

                // Grille de boutons d'actions
                if (_enCoursDeTraitement)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _declencherBiometrie("Faciale"),
                              icon: const Icon(Icons.face_unlock_rounded, color: Colors.white),
                              label: const Text('Scan Facial Bulãli ID', style: TextStyle(color: Colors.white)),
                              // CORRECTION ICI : Remplacement de height par minimumSize
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CouleursSmartCampus.principal, 
                                minimumSize: const Size.fromHeight(50), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _declencherBiometrie("Digital"),
                              icon: const Icon(Icons.fingerprint_rounded, color: Colors.white),
                              label: const Text('Empreinte Digitale', style: TextStyle(color: Colors.white)),
                              // CORRECTION ICI : Remplacement de height par minimumSize
                              style: ElevatedButton.styleFrom(
                                backgroundColor: CouleursSmartCampus.secondaire, 
                                minimumSize: const Size.fromHeight(50), 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _signalerRetard,
                          icon: const Icon(Icons.alarm_add_rounded, color: CouleursSmartCampus.erreur),
                          label: const Text('Signaler le retard de l\'enseignant', style: TextStyle(color: CouleursSmartCampus.erreur, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: CouleursSmartCampus.erreur), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        ),
                      )
                    ],
                  )
              ],
            ),
          ),
        ),
        const SizedBox(width: 32),
        // Petit rappel informatif à droite
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.withOpacity(0.1))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.gavel_rounded, color: Colors.amber),
                SizedBox(height: 16),
                Text('Rappel de déontologie', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(height: 8),
                Text('En tant que Chef de Promotion, toute validation engage votre responsabilité académique. Assurez-vous de la présence effective de l\'enseignant avant le scan.', style: TextStyle(fontSize: 12, color: CouleursSmartCampus.texteSecondaire, height: 1.5)),
              ],
            ),
          ),
        )
      ],
    );
  }

  // 2. VUE CANAL APPARITEUR (ANNONCES + DISCUSSION)
  Widget _construireVueAppariteur() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Espace d\'Échange avec l\'Appariteur', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            children: [
              // Flux d'annonces reçues
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Annonces Publiées', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _annoncesAppariteur.length,
                          itemBuilder: (ctx, idx) {
                            final ann = _annoncesAppariteur[idx];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(color: CouleursSmartCampus.fondPrincipal, borderRadius: BorderRadius.circular(12)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(ann['titre']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                      Text(ann['date']!, style: const TextStyle(fontSize: 11, color: CouleursSmartCampus.texteSecondaire)),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(ann['contenu']!, style: const TextStyle(fontSize: 12, color: CouleursSmartCampus.texteSecondaire, height: 1.4)),
                                ],
                              ),
                            );
                          },
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Simulation chat direct avec l'appariteur
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      const Align(alignment: Alignment.centerLeft, child: Text('Discussion Directe', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                      const Spacer(),
                      const Text('Aucun message direct. Le canal de chat est fluide.', style: TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 12)),
                      const Spacer(),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Écrire à l\'appariteur...',
                          suffixIcon: const Icon(Icons.send_rounded, color: CouleursSmartCampus.principal),
                          filled: true,
                          fillColor: CouleursSmartCampus.fondPrincipal,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      )
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

  // 3. VUE MESSAGERIE PROFS
  Widget _construireVueMessagerieProfs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Espace de Dialogue Enseignants', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text('Ce canal vous permet de recevoir les notifications d\'indisponibilité ou consignes particulières des professeurs.', style: TextStyle(color: CouleursSmartCampus.texteSecondaire, fontSize: 13)),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            children: [
              // Liste des discussions profs
              Expanded(
                flex: 1,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(20)),
                  child: ListView.builder(
                    itemCount: _messagesProfs.length,
                    itemBuilder: (ctx, idx) {
                      final msg = _messagesProfs[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(color: idx == 0 ? CouleursSmartCampus.principal.withOpacity(0.04) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(backgroundColor: CouleursSmartCampus.secondaire.withOpacity(0.1), child: Text(msg['prof']![5])),
                          title: Text(msg['prof']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          subtitle: Text(msg['dernierMessage']!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                          trailing: Text(msg['heure']!, style: const TextStyle(fontSize: 10, color: CouleursSmartCampus.texteSecondaire)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Fenêtre de chat active
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: CouleursSmartCampus.fondSurface, borderRadius: BorderRadius.circular(20)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(backgroundColor: CouleursSmartCampus.principal.withOpacity(0.1), child: const Text('K')),
                          const SizedBox(width: 12),
                          const Text('Prof. Kabasele', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const Divider(height: 32),
                      Expanded(
                        child: ListView(
                          children: [
                            _construireBulleChat("Bonjour cher CP, je serai en retard de 15 minutes pour le cours de Génie Logiciel. Veuillez demander aux étudiants de s'installer calmement.", "09:45", estLui: false),
                          ],
                        ),
                      ),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Répondre au professeur...',
                          suffixIcon: const Icon(Icons.send_rounded, color: CouleursSmartCampus.principal),
                          filled: true,
                          fillColor: CouleursSmartCampus.fondPrincipal,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      )
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

  // Petits widgets utilitaires
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

  Widget _construireBulleChat(String texte, String heure, {required bool estLui}) {
    return Align(
      alignment: estLui ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: estLui ? CouleursSmartCampus.principal : CouleursSmartCampus.fondPrincipal,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(texte, style: TextStyle(fontSize: 13, color: estLui ? Colors.white : CouleursSmartCampus.textePrincipal, height: 1.4)),
            const SizedBox(height: 4),
            Text(heure, style: TextStyle(fontSize: 10, color: estLui ? Colors.white.withOpacity(0.7) : CouleursSmartCampus.texteSecondaire)),
          ],
        ),
      ),
    );
  }
}