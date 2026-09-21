import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/child_photo.dart';
import '../l10n/app_strings.dart';

/// Parent view: child information.
/// Mirrors web `ParentInformation.jsx`: first pick a child via card, then
/// show that child's information entries.
class ParentInformationPage extends StatefulWidget {
  const ParentInformationPage({super.key});

  @override
  State<ParentInformationPage> createState() => _ParentInformationPageState();
}

class _ParentInformationPageState extends State<ParentInformationPage> {
  final ApiService _api = ApiService();
  List<dynamic> _children = [];
  List<dynamic> _informations = [];
  int? _selectedChildId;
  bool _isLoading = true;
  bool _isLoadingInfo = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final children = await _api.getChildren();
      if (!mounted) return;
      setState(() {
        _children = children;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = tr('Gagal memuat data anak.');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadInformation(int childId) async {
    setState(() {
      _isLoadingInfo = true;
      _error = null;
    });
    try {
      final informations = await _api.getChildInformation(childId: childId);
      if (!mounted) return;
      setState(() {
        _informations = informations;
        _isLoadingInfo = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = tr('Gagal memuat informasi.');
        _informations = [];
        _isLoadingInfo = false;
      });
    }
  }

  void _selectChild(int? childId) {
    setState(() {
      _selectedChildId = childId;
      _error = null;
    });
    if (childId != null) {
      _loadInformation(childId);
    } else {
      setState(() {
        _informations = [];
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final parts = dateStr.split(tr('T'));
      final datePart = parts[0];
      final partsDate = datePart.split('-');
      if (partsDate.length == 3) {
        final day = int.tryParse(partsDate[2]) ?? 0;
        final month = int.tryParse(partsDate[1]) ?? 0;
        final year = int.tryParse(partsDate[0]) ?? 0;
        final months = [
          tr('Januari'), tr('Februari'), tr('Maret'), tr('April'), tr('Mei'), tr('Juni'),
          tr('Juli'), tr('Agustus'), tr('September'), tr('Oktober'), tr('November'), tr('Desember'),
        ];
        if (month >= 1 && month <= 12) {
          return '$day ${months[month - 1]} $year';
        }
      }
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr('Informasi Anak'))),
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
                    _loadChildren();
                  },
                )
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final textColor = ThemeHelper.text(context);
    final mutedColor = ThemeHelper.textMuted(context);

    if (_selectedChildId == null) {
      if (_children.isEmpty) {
        return AppWidgets.emptyState(
          icon: Icons.child_care,
          title: tr('Belum ada anak'),
          subtitle: tr('Anda belum memiliki data anak yang terdaftar.'),
        );
      }

      return RefreshIndicator(
        onRefresh: _loadChildren,
        color: AppColors.primary,
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.75,
          ),
          itemCount: _children.length,
          itemBuilder: (context, index) {
            final child = _children[index];

            return GestureDetector(
              onTap: () => _selectChild(child['id']),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: ThemeHelper.surface(context),
                  borderRadius: AppRadius.lgAll,
                  border: Border.all(color: ThemeHelper.border(context)),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Center(
                      child: ChildPhoto(
                        child: child,
                        width: 88,
                        radius: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      child['name'] ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${child['gender'] == 'male' ? tr('Laki-laki') : tr('Perempuan')}'
                      '${_birthLabel(child['birth_date'])}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedColor,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tr('Lihat Informasi'),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    if (_isLoadingInfo) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_informations.isEmpty) {
      final selectedName = _children.firstWhere(
        (c) => c['id'] == _selectedChildId,
        orElse: () => <String, dynamic>{},
      )['name'] ?? '';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(
              tr('Belum ada informasi'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              tr('Belum ada informasi untuk {{selectedName}}.', {'selectedName': selectedName}),
              style: TextStyle(fontSize: 13, color: mutedColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadInformation(_selectedChildId!),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _informations.length,
        itemBuilder: (context, index) {
          final info = _informations[index];
          final priority = info['priority'] ?? 'normal';
          final (label, color, bg) = switch (priority) {
            'urgent' => (tr('Mendesak'), AppColors.error, ThemeHelper.errorBg(context)),
            'important' => (tr('Penting'), AppColors.warning, ThemeHelper.warningBg(context)),
            _ => (tr('Normal'), mutedColor, ThemeHelper.bgAlt(context)),
          };

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            info['title'] ?? '-',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (info['child'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              info['child']['name'] ?? '',
                              style: TextStyle(
                                fontSize: 11,
                                color: mutedColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  info['content'] ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: ThemeHelper.textSecondary(context),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      _formatDate(info['created_at']),
                      style: TextStyle(
                        fontSize: 11,
                        color: mutedColor,
                      ),
                    ),
                    if (info['creator'] != null) ...[
                      const Text(' · ', style: TextStyle(fontSize: 11)),
                      Text(
                        'oleh ${info['creator']['name'] ?? ''}',
                        style: TextStyle(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
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
