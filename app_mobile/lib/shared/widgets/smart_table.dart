import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'section_panel.dart';

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
          headingTextStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
          dataTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}
