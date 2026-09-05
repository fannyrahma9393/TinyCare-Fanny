import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/child_photo.dart';

/// Admin child information detail page — mirrors web ChildInformationDetail.
///
/// Shows full detail of a single information item with title, content,
/// priority badge, child info, and creator info.
class ChildInformationDetailPage extends StatefulWidget {
  final int id;

  const ChildInformationDetailPage({super.key, required this.id});

  @override
  State<ChildInformationDetailPage> createState() => _ChildInformationDetailPageState();
}

class _ChildInformationDetailPageState extends State<ChildInformationDetailPage> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _info;
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
      final info = await _api.getChildInformationDetail(widget.id);
      setState(() {
        _info = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat detail informasi.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);
    final surfaceColor = ThemeHelper.surface(context);
    final borderColor = ThemeHelper.border(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Informasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? AppWidgets.loadingIndicator()
          : _error != null
              ? AppWidgets.errorState(message: _error!, onRetry: _load)
              : _info == null
                  ? AppWidgets.emptyState(
                      icon: Icons.info_outline,
                      title: 'Informasi tidak ditemukan',
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header card
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: AppRadius.lgAll,
                                border: Border.all(color: borderColor),
                                boxShadow: AppColors.cardShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _info!['title'] ?? '-',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                      AppWidgets.statusBadge(
                                        (_info!['priority'] ?? 'normal').toUpperCase(),
                                        _priorityColor(_info!['priority']),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (_info!['child'] != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: ThemeHelper.bgAlt(context),
                                        borderRadius: AppRadius.mdAll,
                                      ),
                                      child: Row(
                                        children: [
                                          ChildPhoto(
                                            child: _info!['child'],
                                            width: 40,
                                            radius: 8,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _info!['child']['name'] ?? '-',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: textColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'Anak',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: mutedColor,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: mutedColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Oleh ${_info!['creator']?['name'] ?? '-'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.schedule,
                                        size: 14,
                                        color: mutedColor,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Dibuat: ${_formatDate(_info!['created_at'])}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: mutedColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Content
                            Text(
                              'Isi Informasi',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: ThemeHelper.bgAlt(context),
                                borderRadius: AppRadius.lgAll,
                                border: Border.all(color: borderColor),
                              ),
                              child: Text(
                                _info!['content'] ?? '',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textColor,
                                  height: 1.7,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Back button
                            OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Kembali'),
                            ),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Color _priorityColor(String? priority) {
    switch (priority) {
      case 'urgent':
        return AppColors.error;
      case 'important':
        return AppColors.warning;
      default:
        return ThemeHelper.textMuted(context);
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';
    final s = value.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }
}
