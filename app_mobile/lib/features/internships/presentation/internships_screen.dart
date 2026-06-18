import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/mock/mock_faculty_data.dart';
import '../../../data/models/faculty_models.dart';
import '../../../data/services/session_service.dart';
import '../../../shared/layouts/responsive_shell.dart';
import '../../../shared/widgets/responsive_grid.dart';
import '../../../shared/widgets/section_panel.dart';
import '../../../shared/widgets/smart_table.dart';
import '../../../shared/widgets/status_badge.dart';

class InternshipsScreen extends StatelessWidget {
  const InternshipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedOffer = MockFacultyData.internshipOffers.first;

    return SmartFacultyShell(
      role: SessionService.currentRole,
      selectedRoute: AppRoutes.internships,
      title: 'Stages',
      subtitle: 'Offres, candidatures, validation et entreprises associées.',
      body: Column(
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
            title: 'Détail d’une offre',
            subtitle: selectedOffer.company,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 18,
                  runSpacing: 14,
                  children: [
                    _DetailBox(label: 'Poste', value: selectedOffer.title),
                    _DetailBox(
                      label: 'Entreprise',
                      value: selectedOffer.company,
                    ),
                    _DetailBox(label: 'Lieu', value: selectedOffer.location),
                    _DetailBox(label: 'Durée', value: selectedOffer.duration),
                    _DetailBox(label: 'Statut', value: selectedOffer.status),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  selectedOffer.description,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          ResponsiveGrid(
            minItemWidth: 340,
            maxColumns: 2,
            children: [
              SectionPanel(
                title: 'Candidature à un stage',
                subtitle: 'Formulaire frontend sans envoi backend.',
                child: Column(
                  children: [
                    const TextField(
                      decoration: InputDecoration(
                        labelText: 'Offre sélectionnée',
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
                        onPressed: () {},
                        icon: const Icon(Icons.send_rounded),
                        label: const Text('Postuler'),
                      ),
                    ),
                  ],
                ),
              ),
              const SmartTable(
                title: 'Suivi des candidatures',
                subtitle: 'État des demandes de stage.',
                columns: [
                  DataColumn(label: Text('Entreprise')),
                  DataColumn(label: Text('Poste')),
                  DataColumn(label: Text('Statut')),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(Text('Kin Digital Lab')),
                      DataCell(Text('Flutter Junior')),
                      DataCell(
                        StatusBadge(label: 'Envoyée', color: AppColors.info),
                      ),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Campus Analytics')),
                      DataCell(Text('Data Analyst')),
                      DataCell(
                        StatusBadge(
                          label: 'Entretien',
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  DataRow(
                    cells: [
                      DataCell(Text('Université Partenaire')),
                      DataCell(Text('Support systèmes')),
                      DataCell(
                        StatusBadge(label: 'Validée', color: AppColors.success),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionPanel(
            title: 'Validation du stage',
            subtitle: 'Entreprise associée et convention.',
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
                      labelText: 'Maître de stage',
                      prefixIcon: Icon(Icons.person_rounded),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Valider'),
                ),
              ],
            ),
          ),
        ],
      ),
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
                color: offer.status == 'Ouverte'
                    ? AppColors.accent
                    : offer.status == 'Sélection'
                    ? AppColors.warning
                    : AppColors.info,
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
            '${offer.company} • ${offer.location}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Text(
            '${offer.duration} • ${offer.applicants} candidatures',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w700,
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
