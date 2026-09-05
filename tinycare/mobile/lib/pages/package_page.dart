import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';

class PackagePage extends StatefulWidget {
  const PackagePage({super.key, required this.childId, required this.childName});

  final int childId;
  final String childName;

  @override
  State<PackagePage> createState() => _PackagePageState();
}

class _PackagePageState extends State<PackagePage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _active;
  List<dynamic> _history = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final active = await _api.getParentChildPackage(widget.childId);
      List<dynamic> history = [];
      try {
        history = await _api.getParentChildPackageHistory(widget.childId);
      } catch (_) {}
      setState(() {
        _active = active;
        _history = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat paket.';
        _isLoading = false;
      });
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'active':
        return 'Aktif';
      case 'expired':
        return 'Berakhir';
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
      appBar: AppBar(title: const Text('Paket')),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(
                  message: _error!,
                  onRetry: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _load();
                  },
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
                        'Riwayat Paket',
                        context: context,
                      ),
                      const SizedBox(height: 12),
                      if (_history.isEmpty)
                        AppWidgets.emptyState(
                          icon: Icons.history,
                          title: 'Belum ada riwayat paket',
                        )
                      else
                        ..._history.map((item) => _buildHistoryItem(item)),
                    ],
                  ),
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
              'Belum ada paket aktif',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ThemeHelper.text(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.childName} belum memiliki paket aktif saat ini.',
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
            'Mulai',
            active['start_date'] ?? '-',
            context: context,
          ),
          AppWidgets.infoRow(
            'Berakhir',
            active['end_date'] ?? '-',
            context: context,
          ),
          if (pkg?['duration_days'] != null)
            AppWidgets.infoRow(
              'Durasi',
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
            'Mulai',
            item['start_date'] ?? '-',
            context: context,
          ),
          AppWidgets.infoRow(
            'Berakhir',
            item['end_date'] ?? '-',
            context: context,
          ),
          AppWidgets.infoRow(
            'Harga',
            CurrencyHelper.formatRupiah(pkg?['price']),
            isTotal: true,
            context: context,
          ),
        ],
      ),
    );
  }
}