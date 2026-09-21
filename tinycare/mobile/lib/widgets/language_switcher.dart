import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_strings.dart';
import '../providers/locale_provider.dart';
import '../theme/app_theme.dart';

/// Compact language switcher for the app bar / settings screens.
class LanguageSwitcher extends StatelessWidget {
  final bool dark;

  const LanguageSwitcher({super.key, this.dark = false});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final muted = ThemeHelper.textMuted(context);

    return PopupMenuButton<String>(
      tooltip: tr('Bahasa'),
      onSelected: (value) => localeProvider.setLocale(value),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: 'id',
          child: Row(
            children: [
              Icon(Icons.check,
                  size: 16,
                  color: localeProvider.locale == 'id'
                      ? AppColors.primary
                      : Colors.transparent),
              const SizedBox(width: 8),
              const Text('Indonesia'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              Icon(Icons.check,
                  size: 16,
                  color: localeProvider.locale == 'en'
                      ? AppColors.primary
                      : Colors.transparent),
              const SizedBox(width: 8),
              const Text('English'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smAll,
          border: Border.all(color: ThemeHelper.border(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.language, size: 16, color: muted),
            const SizedBox(width: 4),
            Text(
              localeProvider.isEnglish ? 'EN' : 'ID',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}