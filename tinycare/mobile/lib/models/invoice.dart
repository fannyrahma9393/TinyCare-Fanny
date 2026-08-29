import '../utils/currency.dart';

class Invoice {
  final int id;
  final int childId;
  final int? packageId;
  final int? voucherId;
  final String invoiceNumber;
  final double subtotal;
  final double discount;
  final double total;
  final String status;
  final String? dueDate;
  final String? paidAt;
  final String? childName;
  final String? packageName;

  Invoice({
    required this.id,
    required this.childId,
    this.packageId,
    this.voucherId,
    required this.invoiceNumber,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.status,
    this.dueDate,
    this.paidAt,
    this.childName,
    this.packageName,
  });

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'paid':
        return 'Lunas';
      case 'failed':
        return 'Gagal';
      case 'expired':
        return 'Kadaluarsa';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String get formattedTotal => CurrencyHelper.formatRupiah(total);
  String get formattedSubtotal => CurrencyHelper.formatRupiah(subtotal);

  /// Check if invoice can be paid.
  bool get canBePaid => status == 'pending';

  /// Check if invoice is overdue.
  bool get isOverdue {
    if (status != 'pending' || dueDate == null) return false;
    final parsed = DateTime.tryParse(dueDate!);
    return parsed != null && parsed.isBefore(DateTime.now());
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      childId: json['child_id'],
      packageId: json['package_id'],
      voucherId: json['voucher_id'],
      invoiceNumber: json['invoice_number'] ?? '',
      subtotal: CurrencyHelper.parseToDouble(json['subtotal']),
      discount: CurrencyHelper.parseToDouble(json['discount']),
      total: CurrencyHelper.parseToDouble(json['total']),
      status: json['status'] ?? 'pending',
      dueDate: json['due_date'],
      paidAt: json['paid_at'],
      childName: json['child'] != null
          ? '${json['child']['first_name'] ?? ''} ${json['child']['last_name'] ?? ''}'.trim()
          : null,
      packageName: json['package']?['name'],
    );
  }
}
