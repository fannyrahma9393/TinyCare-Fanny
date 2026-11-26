import 'package:flutter/material.dart';
import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../widgets/offline_banner.dart';
import '../l10n/app_strings.dart';

class PackagePage extends StatefulWidget {
  const PackagePage({super.key, required this.childId, required this.childName});

  final int childId;
  final String childName;

  @override
  State<PackagePage> createState() => _PackagePageState();
}

class _PackagePageState extends State<PackagePage> with ResourceBinding {
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first active package + package history. History is optional in the
  /// original code (a failure there was swallowed), so it gets its own resource
  /// and never blocks the active package card.
  late final CachedResource<Map<String, dynamic>?> _activeRes;
  late final CachedResource<List<dynamic>> _historyRes;

  Map<String, dynamic>? get _active => _activeRes.data;
  List<dynamic> get _history => _historyRes.data ?? const [];

  String? get _error => _activeRes.error ?? _historyRes.error;
  bool get _isLoading => _activeRes.isLoading;

  @override
  void initState() {
    super.initState();
    _activeRes = CachedResource<Map<String, dynamic>?>(onChanged: onResourceChanged);
    _historyRes = CachedResource<List<dynamic>>(onChanged: onResourceChanged);
    _load();
  }

  Future<void> _load() async {
    await Future.wait([
      _repo.loadChildPackage(widget.childId, _activeRes),
      _repo.loadChildPackageHistory(widget.childId, _historyRes),
    ]);
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return tr('Aktif');
      case 'expired':
        return tr('Berakhir');
      default:
        return status ?? '-';
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'active':
        return AppColors.success;
      case 'expired':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Paket'))),
      body: Column(
        children: [
          OfflineBanner(resource: _activeRes, onRetry: _load),
          Expanded(
            child: _isLoading
                ? AppWidgets.loadingIndicator()
                : _error != null
                    ? AppWidgets.errorState(
                        message: tr(_error!),
                        onRetry: _load,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.primary,
                        child: ListView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          children: [
                            _buildActivePackageCard(),
                            const SizedBox(height: 24),
                            AppWidgets.sectionHeader(
                              tr('Riwayat Paket'),
                              context: context,
                            ),
                            const SizedBox(height: 12),
                            if (_history.isEmpty)
                              AppWidgets.emptyState(
                                icon: Icons.history,
                                title: tr('Belum ada riwayat paket'),
                              )
                            else
                              ..._history.map((item) => _buildHistoryItem(item)),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePackageCard() {
    final active = _active;
    if (active == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeHelper.bgAlt(context),
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: ThemeHelper.border(context)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.textMuted,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              tr('Belum ada paket aktif'),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ThemeHelper.text(context),
              ),
            ),
            const SizedBox(height: 4),                    Text(tr('{{name}} belum memiliki paket aktif saat ini.',
                        {'name': widget.childName}),
              style: TextStyle(
                fontSize: 12,
                color: ThemeHelper.textMuted(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final pkg = active['package'] as Map<String, dynamic>?;
    final name = pkg?['name'] ?? '-';
    final price = pkg?['price'];
    final description = pkg?['description'] as String?;
    final facilities = pkg?['facilities'] as String?;
    final status = active['status'] as String? ?? 'active';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primarySubtle, AppColors.primaryLighter],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.primaryLighter),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: AppTypography.h2.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              AppWidgets.statusBadge(
                _statusLabel(status),
                _statusColor(status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyHelper.formatRupiah(price),
            style: AppTypography.amountLarge.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 16),
          AppWidgets.infoRow(
            tr('Mulai'),
            active['start_date'] ?? '-',
            context: context,
          ),
          AppWidgets.infoRow(
            tr('Berakhir'),
            active['end_date'] ?? '-',
            context: context,
          ),
          if (pkg?['duration_days'] != null)
            AppWidgets.infoRow(
              tr('Durasi'),
              '${pkg!['duration_days']} hari',
              context: context,
            ),
          if (description != null && description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: ThemeHelper.textSecondary(context),
                height: 1.5,
              ),
            ),
          ],
          if (facilities != null && facilities.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              facilities,
              style: TextStyle(
                fontSize: 12,
                color: ThemeHelper.textMuted(context),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(dynamic item) {
    final pkg = item['package'] as Map<String, dynamic>?;
    final status = item['status'] as String? ?? '-';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeHelper.surface(context),
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: ThemeHelper.border(context)),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pkg?['name'] ?? '-',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ThemeHelper.text(context),
                  ),
                ),
              ),
              AppWidgets.statusBadge(
                _statusLabel(status),
                _statusColor(status),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppWidgets.infoRow(
            tr('Mulai'),
            item['start_date'] ?? '-',
            context: context,
          ),
          AppWidgets.infoRow(
            tr('Berakhir'),
            item['end_date'] ?? '-',
            context: context,
          ),
          AppWidgets.infoRow(
            tr('Harga'),
            CurrencyHelper.formatRupiah(pkg?['price']),
            isTotal: true,
            context: context,
          ),
        ],
      ),
    );
  }
}