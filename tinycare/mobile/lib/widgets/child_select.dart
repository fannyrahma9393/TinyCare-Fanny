import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'child_photo.dart';
import '../l10n/app_strings.dart';

/// Shared child-picker used by PARENT flows (Activities, Development, Child
/// Information, Daily Stories) to mirror the web "child card" selection.
/// Tapping a child invokes [onTap] with the child map.
class ChildPickerGrid extends StatelessWidget {
  const ChildPickerGrid({
    super.key,
    required this.children,
    required this.onTap,
    this.actionLabel = 'Lihat',
    this.photoWidth = 88,
  });

  final List<dynamic> children;
  final void Function(dynamic child) onTap;
  final String actionLabel;
  final double photoWidth;

  @override
  Widget build(BuildContext context) {
    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.77,
      ),
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];
        return GestureDetector(
          onTap: () => onTap(child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: borderColor),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                ChildPhoto(child: child, width: photoWidth, radius: 16),
                const SizedBox(height: 12),
                Text(
                  child['name'] ?? '-',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '${child['gender'] == 'male' ? tr('Laki-laki') : tr('Perempuan')}'
                      '${_birthLabel(child['birth_date'])}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: mutedColor),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, size: 14, color: AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _birthLabel(dynamic birthDate) {
    if (birthDate == null || birthDate.toString().isEmpty) return '';
    try {
      final parts = birthDate.toString().split('-');
      if (parts.length == 3) {
        final monthNames = [
          tr('Jan'), tr('Feb'), tr('Mar'), tr('Apr'), tr('Mei'), tr('Jun'),
          tr('Jul'), tr('Agu'), tr('Sep'), tr('Okt'), tr('Nov'), tr('Des'),
        ];
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[0]);
        final label = m != null && m >= 1 && m <= 12 ? monthNames[m - 1] : parts[1];
        return ' · $label ${y ?? parts[0]}';
      }
    } catch (_) {}
    return tr(' · {{birthDate}}', {'birthDate': birthDate});
  }
}

/// Header showing the child's 4:6 photo, name and meta — mirrors the web
/// detail page header (96px wide photo).
class ChildHeader extends StatelessWidget {
  const ChildHeader({
    super.key,
    required this.child,
    this.subtitle,
    this.photoWidth = 96,
  });

  final Map<String, dynamic>? child;
  final String? subtitle;
  final double photoWidth;

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final name = child?['name'] ?? '-';
    final gender = child?['gender'];
    final birthDate = child?['birth_date'];

    return Row(
      children: [
        ChildPhoto(child: child, width: photoWidth, radius: 16),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.h1.copyWith(color: textColor)),
              const SizedBox(height: 4),
              Text(
                '${gender == 'male' ? tr('Laki-laki') : tr('Perempuan')} · ${birthDate ?? '-'}',
                style: TextStyle(fontSize: 13, color: mutedColor),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: TextStyle(fontSize: 12, color: mutedColor)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}