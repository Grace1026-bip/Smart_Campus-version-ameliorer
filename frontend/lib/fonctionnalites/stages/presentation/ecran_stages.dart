import 'package:flutter/material.dart';

import '../../../coeur/routes/routes_application.dart';
import '../../../coeur/theme/couleurs_application.dart';
import '../../../donnees/donnees_fictives/donnees_faculte_fictives.dart';
import '../../../donnees/modeles/modeles_faculte.dart';
import '../../../donnees/services/service_session.dart';
import '../../../commun/mises_en_page/structure_adaptative.dart';
import '../../../commun/composants/grille_adaptative.dart';
import '../../../commun/composants/panneau_section.dart';
import '../../../commun/composants/tableau_intelligent.dart';
import '../../../commun/composants/badge_statut.dart';

class InternshipsScreen extends StatelessWidget {
  const InternshipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = SessionService.currentRole;
    final canAccessStages = _canAccessStages(role);
    final selectedOffer = MockFacultyData.internshipOffers.first;

    return SmartFacultyShell(
      role: role,
      selectedRoute: AppRoutes.internships,
      title: _titleFor(role),
      subtitle: _subtitleFor(role),
      body: canAccessStages
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveGrid(
                  minItemWidth: 290,
                  maxColumns: 3,
                  children: [
                    for (final offer in MockFacultyData.internshipOffers)
                      _OfferCard(offer: offer),
                  ],
                ),
                const SizedBox(height: 22),
                SectionPanel(
                  title: 'Detail d une offre',
                  subtitle: selectedOffer.company,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 18,
                        runSpacing: 14,
                        children: [
                          _DetailBox(
                              label: 'Poste', value: selectedOffer.title),
                          _DetailBox(
                            label: 'Entreprise',
                            value: selectedOffer.company,
                          ),
                          _DetailBox(
                              label: 'Lieu', value: selectedOffer.location),
                          _DetailBox(
                              label: 'Duree', value: selectedOffer.duration),
                          _DetailBox(
                              label: 'Statut', value: selectedOffer.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        selectedOffer.description,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final item in selectedOffer.requirements)
                            Chip(
                              label: Text(item),
                              backgroundColor: AppColors.primarySoft,
                              side: const BorderSide(color: AppColors.border),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                ResponsiveGrid(
                  minItemWidth: 340,
                  maxColumns: 2,
                  children: [
                    _RoleInternshipPanel(role: role),
                    const _ApplicationsTable(),
                  ],
                ),
                const SizedBox(height: 22),
                const _PartnersTable(),
                if (role == UserRole.administrator ||
                    role == UserRole.apparitor) ...[
                  const SizedBox(height: 22),
                  const _ValidationPanel(),
                ],
              ],
            )
          : const _StageReservedMessage(),
    );
  }
}

class _StageReservedMessage extends StatelessWidget {
  const _StageReservedMessage();

  @override
  Widget build(BuildContext context) {
    return const SectionPanel(
      title: 'Module stage reserve',
      subtitle: 'Regle academique appliquee par promotion.',
      child: Text(
        'Le module stage est reserve aux promotions L3, L4 et M2.',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w900,
          height: 1.4,
        ),
      ),
    );
  }
}

class _RoleInternshipPanel extends StatelessWidget {
  const _RoleInternshipPanel({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    if (role == UserRole.administrator) {
      return const SectionPanel(
        title: 'Suivi administratif',
        subtitle: 'Controler offres, candidatures et conventions.',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StageSignal(icon: Icons.apartment_rounded, text: 'Entreprises'),
            _StageSignal(icon: Icons.assignment_rounded, text: 'Conventions'),
            _StageSignal(icon: Icons.verified_rounded, text: 'Validations'),
          ],
        ),
      );
    }

    if (role == UserRole.dean || role == UserRole.apparitor) {
      return const SectionPanel(
        title: 'Lecture globale',
        subtitle: 'Suivre insertion professionnelle et partenariats.',
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _StageSignal(icon: Icons.trending_up_rounded, text: 'Taux stage'),
            _StageSignal(icon: Icons.business_rounded, text: 'Partenaires'),
            _StageSignal(icon: Icons.school_rounded, text: 'Promotions'),
          ],
        ),
      );
    }

    return SectionPanel(
      title: 'Candidature a un stage',
      subtitle: 'Preparez une demande claire pour l offre selectionnee.',
      child: Column(
        children: [
          const TextField(
            decoration: InputDecoration(
              labelText: 'Offre selectionnee',
              prefixIcon: Icon(Icons.business_center_rounded),
            ),
          ),
          const SizedBox(height: 12),
          const TextField(
            minLines: 3,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Motivation',
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('La candidature est prete a etre envoyee.'),
                ),
              ),
              icon: const Icon(Icons.send_rounded),
              label: const Text('Postuler'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApplicationsTable extends StatelessWidget {
  const _ApplicationsTable();

  @override
  Widget build(BuildContext context) {
    return SmartTable(
      title: 'Suivi des candidatures',
      subtitle: 'Etat des demandes de stage.',
      columns: const [
        DataColumn(label: Text('Etudiant')),
        DataColumn(label: Text('Entreprise')),
        DataColumn(label: Text('Poste')),
        DataColumn(label: Text('Statut')),
      ],
      rows: [
        for (final application in MockFacultyData.internshipApplications)
          DataRow(
            cells: [
              DataCell(Text(application.student)),
              DataCell(Text(application.company)),
              DataCell(Text(application.position)),
              DataCell(
                StatusBadge(
                  label: application.status,
                  color: _statusColor(application.status),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _PartnersTable extends StatelessWidget {
  const _PartnersTable();

  @override
  Widget build(BuildContext context) {
    return SmartTable(
      title: 'Entreprises partenaires',
      subtitle: 'Partenaires actifs pour les stages facultaires.',
      columns: const [
        DataColumn(label: Text('Entreprise')),
        DataColumn(label: Text('Secteur')),
        DataColumn(label: Text('Stagiaires')),
        DataColumn(label: Text('Convention')),
      ],
      rows: [
        for (final partner in MockFacultyData.partnerCompanies)
          DataRow(
            cells: [
              DataCell(Text(partner.name)),
              DataCell(Text(partner.sector)),
              DataCell(Text('${partner.activeInterns}')),
              DataCell(Text(partner.agreementStatus)),
            ],
          ),
      ],
    );
  }
}

class _ValidationPanel extends StatelessWidget {
  const _ValidationPanel();

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: 'Validation du stage',
      subtitle: 'Associer l etudiant, l entreprise et la convention.',
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          const SizedBox(
            width: 260,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Entreprise',
                prefixIcon: Icon(Icons.apartment_rounded),
              ),
            ),
          ),
          const SizedBox(
            width: 260,
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Maitre de stage',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La validation est prete a etre enregistree.'),
              ),
            ),
            icon: const Icon(Icons.verified_rounded),
            label: const Text('Valider'),
          ),
        ],
      ),
    );
  }
}

class _StageSignal extends StatelessWidget {
  const _StageSignal({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: AppColors.primary, size: 18),
      label: Text(text),
      backgroundColor: AppColors.primarySoft,
      side: const BorderSide(color: AppColors.border),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.offer});

  final InternshipOffer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.business_center_rounded,
                color: AppColors.primary,
              ),
              const Spacer(),
              StatusBadge(
                label: offer.status,
                color: _statusColor(offer.status),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            offer.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${offer.company} - ${offer.location}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            '${offer.duration} - ${offer.applicants} candidatures',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailBox extends StatelessWidget {
  const _DetailBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  if (status == 'Ouverte' || status == 'Validee') return AppColors.success;
  if (status == 'Selection' || status == 'Entretien') return AppColors.warning;
  return AppColors.info;
}

String _titleFor(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'Mes stages';
    case UserRole.administrator:
      return 'Gestion des stages';
    case UserRole.apparitor:
      return 'Suivi apparitorat des stages';
    case UserRole.dean:
      return 'Suivi des stages';
    case UserRole.teacher:
      return 'Stages encadres';
    case UserRole.promotionChief:
      return 'Stages de la promotion';
  }
}

String _subtitleFor(UserRole role) {
  switch (role) {
    case UserRole.student:
      return 'Consulter les offres, postuler et suivre vos candidatures.';
    case UserRole.administrator:
      return 'Valider stages, conventions et entreprises associees.';
    case UserRole.apparitor:
      return 'Verifier les stages reserves aux promotions L3, L4 et M2.';
    case UserRole.dean:
      return 'Observer les tendances d insertion et les partenariats.';
    case UserRole.teacher:
      return 'Consulter les stages lies aux etudiants encadres.';
    case UserRole.promotionChief:
      return 'Relayer les echeances et suivre la promotion.';
  }
}

bool _canAccessStages(UserRole role) {
  if (role == UserRole.administrator ||
      role == UserRole.apparitor ||
      role == UserRole.teacher ||
      role == UserRole.dean) {
    return true;
  }
  final promotion = SessionService.currentUser.promotion;
  return promotion.startsWith('L3') ||
      promotion.startsWith('L4') ||
      promotion.startsWith('M2');
}
