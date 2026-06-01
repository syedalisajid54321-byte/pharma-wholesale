// lib/models/transaction.dart
enum TransactionType { invoice, payment }

class Transaction {
  final String id;
  final String doctorId;
  final String doctorName;
  final TransactionType type;
  final double amount;
  final double previousBalance;
  final double newBalance;
  final String reference; // invoice number or receipt number
  final String notes;
  final DateTime date;

  Transaction({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.type,
    required this.amount,
    required this.previousBalance,
    required this.newBalance,
    required this.reference,
    this.notes = '',
    required this.date,
  });

  factory Transaction.fromMap(Map<String, dynamic> map, String id) {
    return Transaction(
      id: id,
      doctorId: map['doctorId'] ?? '',
      doctorName: map['doctorName'] ?? '',
      type: map['type'] == 'payment'
          ? TransactionType.payment
          : TransactionType.invoice,
      amount: (map['amount'] ?? 0.0).toDouble(),
      previousBalance: (map['previousBalance'] ?? 0.0).toDouble(),
      newBalance: (map['newBalance'] ?? 0.0).toDouble(),
      reference: map['invoiceNumber'] ?? map['receiptNumber'] ?? '',
      notes: map['notes'] ?? '',
      date: map['date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['date'])
          : DateTime.now(),
    );
  }
}
