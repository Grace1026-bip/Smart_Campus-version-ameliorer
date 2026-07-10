import 'package:flutter/material.dart';

import '../../coeur/theme/couleurs_application.dart';
import 'panneau_section.dart';

class SmartTable extends StatelessWidget {
  const SmartTable({
    super.key,
    required this.title,
    this.subtitle,
    required this.columns,
    required this.rows,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SectionPanel(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.primarySoft),
          headingTextStyle: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
          dataTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          dividerThickness: 0.8,
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}
