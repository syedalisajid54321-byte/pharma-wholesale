// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/doctor.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../models/transaction.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ─── Auth ────────────────────────────────────────────────
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() => _auth.signOut();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─── Doctors ─────────────────────────────────────────────
  CollectionReference get _doctors => _db.collection('doctors');
  CollectionReference get _invoices => _db.collection('invoices');
  CollectionReference get _payments => _db.collection('payments');

  Stream<List<Doctor>> watchDoctors() {
    return _doctors
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Doctor.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<void> addDoctor(Doctor doctor) async {
    await _doctors.add(doctor.toMap());
  }

  Future<void> updateDoctor(Doctor doctor) async {
    await _doctors.doc(doctor.id).update(doctor.toMap());
  }

  Future<void> deleteDoctor(String doctorId) async {
    // Delete doctor and all their transactions
    final batch = _db.batch();
    batch.delete(_doctors.doc(doctorId));

    final invSnap =
        await _invoices.where('doctorId', isEqualTo: doctorId).get();
    for (var d in invSnap.docs) {
      batch.delete(d.reference);
    }

    final paySnap =
        await _payments.where('doctorId', isEqualTo: doctorId).get();
    for (var d in paySnap.docs) {
      batch.delete(d.reference);
    }

    await batch.commit();
  }

  // ─── Invoices ────────────────────────────────────────────
  Future<String> generateInvoiceNumber() async {
    final snap = await _invoices.orderBy('date', descending: true).limit(1).get();
    if (snap.docs.isEmpty) return 'INV-0001';
    final last = snap.docs.first.data() as Map<String, dynamic>;
    final lastNum = last['invoiceNumber'] as String? ?? 'INV-0000';
    final num = int.tryParse(lastNum.split('-').last) ?? 0;
    return 'INV-${(num + 1).toString().padLeft(4, '0')}';
  }

  Future<void> createInvoice({
    required Doctor doctor,
    required double amount,
    required String notes,
  }) async {
    final batch = _db.batch();
    final invoiceRef = _invoices.doc();
    final invoiceNumber = await generateInvoiceNumber();
    final previousBalance = doctor.balance;
    final newBalance = previousBalance + amount;

    final invoice = Invoice(
      id: invoiceRef.id,
      doctorId: doctor.id,
      doctorName: doctor.name,
      amount: amount,
      previousBalance: previousBalance,
      newBalance: newBalance,
      notes: notes,
      date: DateTime.now(),
      invoiceNumber: invoiceNumber,
    );

    batch.set(invoiceRef, invoice.toMap());
    batch.update(_doctors.doc(doctor.id), {'balance': newBalance});
    await batch.commit();
  }

  Stream<List<Invoice>> watchDoctorInvoices(String doctorId) {
    return _invoices
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Invoice.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Stream<List<Invoice>> watchAllInvoices() {
    return _invoices
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Invoice.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ─── Payments ────────────────────────────────────────────
  Future<String> generateReceiptNumber() async {
    final snap =
        await _payments.orderBy('date', descending: true).limit(1).get();
    if (snap.docs.isEmpty) return 'RCP-0001';
    final last = snap.docs.first.data() as Map<String, dynamic>;
    final lastNum = last['receiptNumber'] as String? ?? 'RCP-0000';
    final num = int.tryParse(lastNum.split('-').last) ?? 0;
    return 'RCP-${(num + 1).toString().padLeft(4, '0')}';
  }

  Future<void> recordPayment({
    required Doctor doctor,
    required double amount,
    required String notes,
  }) async {
    final batch = _db.batch();
    final paymentRef = _payments.doc();
    final receiptNumber = await generateReceiptNumber();
    final previousBalance = doctor.balance;
    final newBalance = previousBalance - amount;

    final payment = Payment(
      id: paymentRef.id,
      doctorId: doctor.id,
      doctorName: doctor.name,
      amount: amount,
      previousBalance: previousBalance,
      newBalance: newBalance,
      notes: notes,
      date: DateTime.now(),
      receiptNumber: receiptNumber,
    );

    batch.set(paymentRef, payment.toMap());
    batch.update(_doctors.doc(doctor.id), {'balance': newBalance});
    await batch.commit();
  }

  Stream<List<Payment>> watchDoctorPayments(String doctorId) {
    return _payments
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Payment.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Stream<List<Payment>> watchAllPayments() {
    return _payments
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Payment.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  // ─── Ledger ──────────────────────────────────────────────
  Stream<List<Transaction>> watchDoctorLedger(String doctorId) {
    final invoiceStream = _invoices
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                Transaction.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());

    final paymentStream = _payments
        .where('doctorId', isEqualTo: doctorId)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                Transaction.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());

    return invoiceStream.asyncExpand((invoices) async* {
      yield invoices;
    });
    // Note: In production, combine streams properly using RxDart or StreamZip
  }

  // ─── Reports ─────────────────────────────────────────────
  Future<Map<String, dynamic>> getDailyReport(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    final invSnap = await _invoices
        .where('date',
            isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
            isLessThan: end.millisecondsSinceEpoch)
        .get();

    final paySnap = await _payments
        .where('date',
            isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
            isLessThan: end.millisecondsSinceEpoch)
        .get();

    double totalInvoices = 0;
    double totalPayments = 0;

    for (var d in invSnap.docs) {
      totalInvoices += ((d.data() as Map)['amount'] ?? 0).toDouble();
    }
    for (var d in paySnap.docs) {
      totalPayments += ((d.data() as Map)['amount'] ?? 0).toDouble();
    }

    return {
      'invoiceCount': invSnap.docs.length,
      'paymentCount': paySnap.docs.length,
      'totalInvoices': totalInvoices,
      'totalPayments': totalPayments,
    };
  }

  Future<Map<String, dynamic>> getMonthlyReport(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final invSnap = await _invoices
        .where('date',
            isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
            isLessThan: end.millisecondsSinceEpoch)
        .get();

    final paySnap = await _payments
        .where('date',
            isGreaterThanOrEqualTo: start.millisecondsSinceEpoch,
            isLessThan: end.millisecondsSinceEpoch)
        .get();

    double totalInvoices = 0;
    double totalPayments = 0;

    for (var d in invSnap.docs) {
      totalInvoices += ((d.data() as Map)['amount'] ?? 0).toDouble();
    }
    for (var d in paySnap.docs) {
      totalPayments += ((d.data() as Map)['amount'] ?? 0).toDouble();
    }

    return {
      'invoiceCount': invSnap.docs.length,
      'paymentCount': paySnap.docs.length,
      'totalInvoices': totalInvoices,
      'totalPayments': totalPayments,
    };
  }
}
