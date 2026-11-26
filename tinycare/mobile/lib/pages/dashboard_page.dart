import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/cached_resource.dart';
import '../services/parent_data_repository.dart';
import '../theme/app_theme.dart';
import '../utils/currency.dart';
import '../widgets/child_photo.dart';
import '../widgets/offline_banner.dart';
import 'child_detail_page.dart';
import 'invoice_detail_page.dart';
import '../l10n/app_strings.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with ResourceBinding {
  final ParentDataRepository _repo = ParentDataRepository();

  /// Cache-first dashboard: the last snapshot renders immediately, then the
  /// API refreshes it when the backend is reachable.
  late final CachedResource<Map<String, dynamic>> _res;
  Map<String, dynamic>? get _dashboardData => _res.data;

  @override
  void initState() {
    super.initState();
    _res = CachedResource<Map<String, dynamic>>(
      onChanged: onResourceChanged,
      isEmptyData: (data) => data.isEmpty,
    );
    _loadDashboard();
  }

  Future<void> _loadDashboard() => _repo.loadDashboard(_res);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Dashboard')),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () {
              final auth = context.read<AuthProvider>();
              auth.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          OfflineBanner(resource: _res, onRetry: _loadDashboard),
          Expanded(
            child: _res.isLoading
                ? AppWidgets.loadingIndicator()
                : _res.error != null
                    ? AppWidgets.errorState(
                        message: tr(_res.error!),
                        onRetry: _loadDashboard,
                      )
                    : _buildDashboard(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final auth = context.watch<AuthProvider>();
    final children = _dashboardData?['children'] ?? [];
    final pendingInvoices = _dashboardData?['pending_invoices'] ?? [];
    final announcements = _dashboardData?['announcements'] ?? [];
    final upcomingEvents = _dashboardData?['upcoming_events'] ?? [];
    final childInformation = _dashboardData?['child_information'] ?? [];

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Greeting
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
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
                  Text(
                    tr('Halo, {{name}} 👋', {
                      'name': auth.user?['name']?.split(' ').first ?? tr('Orang Tua'),
                    }),
                    style: AppTypography.h1.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr('Pantau perkembangan si kecil dengan mudah.'),
                    style: TextStyle(
                      fontSize: 14,
                      color: ThemeHelper.textSecondary(context),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Summary Cards (matching web: Anak, Tagihan, Pengumuman, Jadwal)
            Row(
              children: [
                _buildSummaryCard(tr('Anak'), '${children.length}',
                    AppColors.primary),
                const SizedBox(width: 10),
                _buildSummaryCard(
                    tr('Tagihan'),
                    '${pendingInvoices.length}',
                    pendingInvoices.isNotEmpty
                        ? AppColors.warning
                        : ThemeHelper.textMuted(context)),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSummaryCard(tr('Pengumuman'), '${announcements.length}',
                    AppColors.info),
                const SizedBox(width: 10),
                _buildSummaryCard(
                    tr('Jadwal'),
                    '${upcomingEvents.length}',
                    upcomingEvents.isNotEmpty
                        ? AppColors.info
                        : ThemeHelper.textMuted(context)),
              ],
            ),
            const SizedBox(height: 28),

            // Children Section (matching web)
            if (children.isNotEmpty) ...[
              Text(tr('Anak Saya'),
                  style: AppTypography.h3
                      .copyWith(color: ThemeHelper.text(context))),
              const SizedBox(height: 14),
              ...List.generate(children.length,
                  (i) => _buildChildCardCompact(children[i])),
              const SizedBox(height: 28),
            ],

            // Child Information Section (matching web)
            if (childInformation.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(tr('Informasi Anak'),
                      style: AppTypography.h3
                          .copyWith(color: ThemeHelper.text(context))),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushNamed(context, '/parent/information'),
                    child: Text(tr('Lihat Semua'),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...List.generate(
                childInformation.length > 3 ? 3 : childInformation.length,
                (i) => _buildChildInfoCard(childInformation[i]),
              ),
              const SizedBox(height: 28),
            ],

            // Two Column: Invoices + Events (matching web)
            if (pendingInvoices.isNotEmpty || upcomingEvents.isNotEmpty) ...[
              if (pendingInvoices.isNotEmpty) ...[
                Text(tr('Invoice Pending'),
                    style: AppTypography.h3
                        .copyWith(color: ThemeHelper.text(context))),
                const SizedBox(height: 14),
                ...List.generate(pendingInvoices.length,
                    (i) => _buildPendingInvoiceCard(pendingInvoices[i])),
                const SizedBox(height: 28),
              ],
              if (upcomingEvents.isNotEmpty) ...[
                Text(tr('Jadwal Mendatang'),
                    style: AppTypography.h3
                        .copyWith(color: ThemeHelper.text(context))),
                const SizedBox(height: 14),
                ...List.generate(upcomingEvents.length > 3
                    ? 3
                    : upcomingEvents.length,
                    (i) => _buildEventCard(upcomingEvents[i])),
                const SizedBox(height: 28),
              ],
            ],

            // Recent Announcements (matching web)
            if (announcements.isNotEmpty) ...[
              Text(tr('Pengumuman'),
                  style: AppTypography.h3
                      .copyWith(color: ThemeHelper.text(context))),
              const SizedBox(height: 14),
              ...List.generate(
                announcements.length > 3 ? 3 : announcements.length,
                (i) => _buildAnnouncementCard(announcements[i]),
              ),
            ],

            // Empty state
            if (children.isEmpty &&
                pendingInvoices.isEmpty &&
                announcements.isEmpty)
              AppWidgets.emptyState(
                icon: Icons.dashboard_outlined,
                title: tr('Belum ada data'),
                subtitle:
                    tr('Data akan muncul ketika sudah tersedia di sistem.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color valueColor) {
    return Expanded(
      child: Builder(builder: (context) {
        final surfaceColor = ThemeHelper.surface(context);
        final borderColor = ThemeHelper.border(context);
        final labelColor = ThemeHelper.textMuted(context);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: borderColor),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: AppTypography.label.copyWith(color: labelColor)),
              const SizedBox(height: 8),
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                      height: 1)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChildCardCompact(dynamic child) {
    final packages = child['child_packages'] ?? [];
    final activePackage =
        packages.isNotEmpty ? packages.first['package'] : null;
    final todayAttendance = child['today_attendance'];
    final todayStory = child['today_story'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChildDetailPage(childId: child['id'])),
      ),
      child: Builder(builder: (context) {
        final mutedColor = ThemeHelper.textMuted(context);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: ThemeHelper.surface(context),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: ThemeHelper.border(context)),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              // Child info row
              Row(
                children: [
                  ChildPhoto(child: child, width: 48),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child['name'] ?? '-',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: ThemeHelper.text(context))),
                        const SizedBox(height: 2),
                        Text(
                          '${child['gender'] == 'male' ? tr('Laki-laki') : tr('Perempuan')}${child['birth_date'] != null ? ' · ${child['birth_date']}' : ''}',
                          style: TextStyle(
                              fontSize: 12, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: mutedColor),
                ],
              ),

              // Active package
              if (activePackage != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ThemeHelper.successBg(context),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activePackage['name'] ?? '-',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success)),
                      const SizedBox(height: 2),
                      Text(
                        'Berlaku s/d ${activePackage['end_date'] ?? '-'}',
                        style: TextStyle(
                            fontSize: 12, color: mutedColor),
                      ),
                    ],
                  ),
                ),
              ],

              // Today attendance (matching web)
              if (todayAttendance != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppWidgets.statusBadge(tr('Hadir'), AppColors.success),
                    const SizedBox(width: 8),
                    if (todayAttendance['check_in_time'] != null)
                      Text(
                          tr('Masuk: {{time}}',
                              {'time': todayAttendance['check_in_time']}),
                          style: TextStyle(
                              fontSize: 12, color: mutedColor)),
                  ],
                ),
              ],

              // Today story (matching web)
              if (todayStory != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ThemeHelper.bgAlt(context),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Text(
                    todayStory['summary'] ??
                        'Mood: ${todayStory['mood'] ?? '-'}',
                    style: TextStyle(
                        fontSize: 12,
                        color: ThemeHelper.textSecondary(context)),
                  ),
                ),
              ],

              // Lihat Detail link (matching web)
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(tr('Lihat Detail'),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right,
                      size: 14, color: AppColors.primary),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChildInfoCard(dynamic info) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/parent/information'),
      child: Builder(builder: (context) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ThemeHelper.surface(context),
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: ThemeHelper.border(context)),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: ThemeHelper.infoBg(context),
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(Icons.info_outline,
                    size: 16, color: AppColors.info),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(info['child']?['name'] ?? '',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ThemeHelper.text(context))),
                    Text(info['type'] ?? '',
                        style: TextStyle(
                            fontSize: 11,
                            color: ThemeHelper.textMuted(context))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  size: 16, color: ThemeHelper.textMuted(context)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEventCard(dynamic event) {
    return Builder(builder: (context) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThemeHelper.infoBg(context),
          borderRadius: AppRadius.lgAll,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: ThemeHelper.surface(context),
                borderRadius: AppRadius.smAll,
              ),
              child: const Icon(Icons.calendar_today,
                  size: 16, color: AppColors.info),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event['title'] ?? '-',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ThemeHelper.text(context))),
                  Text(
                      '${event['date'] ?? '-'} · ${event['start_time'] ?? '-'}',
                      style: TextStyle(
                          fontSize: 12,
                          color: ThemeHelper.textMuted(context))),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildPendingInvoiceCard(dynamic inv) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => InvoiceDetailPage(invoiceId: inv['id'])),
      ),
      child: Builder(builder: (context) {
        final warningBgColor = ThemeHelper.warningBg(context);
        final mutedColor = ThemeHelper.textMuted(context);
        final textColor = ThemeHelper.text(context);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: warningBgColor,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: AppRadius.smAll,
                ),
                child: const Icon(Icons.receipt,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv['invoice_number'] ?? '-',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    const SizedBox(height: 2),
                    Text(
                        tr('{{name}} · Jatuh tempo: {{due}}', {
                          'name': inv['child']?['name'] ?? '',
                          'due': inv['due_date'] ?? '-',
                        }),
                        style: TextStyle(
                            fontSize: 12, color: mutedColor)),
                  ],
                ),
              ),
              Text(CurrencyHelper.formatRupiah(inv['total']),
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAnnouncementCard(dynamic ann) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/announcements'),
      child: Builder(builder: (context) {
        final textColor = ThemeHelper.text(context);
        final textSecColor = ThemeHelper.textSecondary(context);
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
              Text(ann['title'] ?? '-',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor)),
              const SizedBox(height: 6),
              Text(ann['content'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 13,
                      color: textSecColor,
                      height: 1.5)),
            ],
          ),
        );
      }),
    );
  }
}
