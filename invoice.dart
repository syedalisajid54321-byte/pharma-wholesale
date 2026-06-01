// lib/models/invoice.dart
class Invoice {
  final String id;
  final String doctorId;
  final String doctorName;
  final double amount;
  final double previousBalance;
  final double newBalance;
  final String notes;
  final DateTime date;
  final String invoiceNumber;

  Invoice({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.amount,
    required this.previousBalance,
    required this.newBalance,
    this.notes = '',
    required this.date,
    required this.invoiceNumber,
  });

  factory Invoice.fromMap(Map<String, dynamic> map, String id) {
    return Invoice(
      id: id,
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      previousBalance: (map['previousBalance'] ?? 0.0).toDouble(),
      newBalance: (map['newBalance'] ?? 0.0).toDouble(),
      notes: map['notes'] ?? '',
      date: map['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date'])
          : DateTime.now(),
      invoiceNumber: map['invoiceNumber'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'doctorName': doctorName,
      'amount': amount,
      'previousBalance': previousBalance,
      'newBalance': newBalance,
      'notes': notes,
      'date': date.millisecondsSinceEpoch,
      'invoiceNumber': invoiceNumber,
      'type': 'invoice',
    };
  }
}
