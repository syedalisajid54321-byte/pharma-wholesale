// lib/screens/payments_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/doctor.dart';
import '../models/payment.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: Text(PS.payments)),
      body: StreamBuilder<List<Payment>>(
        stream: svc.watchAllPayments(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final payments = snap.data ?? [];

          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.payments_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('هیڅ ادایيګي نه دي',
                      style: GoogleFonts.cairo(
                          color: AppTheme.textSecondary, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: payments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _PaymentTile(payment: payments[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRecordPayment(context, svc),
        icon: const Icon(Icons.add),
        label: Text(PS.recordPayment, style: GoogleFonts.cairo()),
        backgroundColor: AppTheme.accent,
      ),
    );
  }

  void _showRecordPayment(BuildContext context, FirebaseService svc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _RecordPaymentForm(svc: svc),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    payment.receiptNumber,
                    style: GoogleFonts.cairo(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  payment.doctorName,
                  style: GoogleFonts.cairo(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _row('ادا شوی', Fmt.money(payment.amount),
                valueColor: AppTheme.accent),
            _row('پخوانی پاتې', Fmt.money(payment.previousBalance)),
            _row('نوی پاتې', Fmt.money(payment.newBalance),
                valueColor: AppTheme.primary),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Fmt.date(payment.date),
                    style: GoogleFonts.cairo(
                        color: AppTheme.textSecondary, fontSize: 12)),
                if (payment.notes.isNotEmpty)
                  Text(payment.notes,
                      style: GoogleFonts.cairo(
                          color: AppTheme.textSecondary, fontSize: 12),
                      textDirection: TextDirection.rtl),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(value,
              style: GoogleFonts.cairo(
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppTheme.textPrimary,
                  fontSize: 14)),
          Text(label,
              style: GoogleFonts.cairo(
                  color: AppTheme.textSecondary, fontSize: 13),
              textDirection: TextDirection.rtl),
        ],
      ),
    );
  }
}

class _RecordPaymentForm extends StatefulWidget {
  final FirebaseService svc;
  const _RecordPaymentForm({required this.svc});

  @override
  State<_RecordPaymentForm> createState() => _RecordPaymentFormState();
}

class _RecordPaymentFormState extends State<_RecordPaymentForm> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  Doctor? _selectedDoctor;
  List<Doctor> _doctors = [];
  bool _saving = false;
  bool _loadingDoctors = true;

  @override
  void initState() {
    super.initState();
    widget.svc.watchDoctors().listen((docs) {
      if (mounted) setState(() {
        _doctors = docs;
        _loadingDoctors = false;
      });
    });
  }

  Future<void> _save() async {
    if (_selectedDoctor == null || _amountCtrl.text.trim().isEmpty) return;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;

    setState(() => _saving = true);
    try {
      await widget.svc.recordPayment(
        doctor: _selectedDoctor!,
        amount: amount,
        notes: _notesCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(PS.recordPayment,
              style: GoogleFonts.cairo(fontSize: 20, fontWeight: FontWeight.w700),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right),
          const SizedBox(height: 20),
          if (_loadingDoctors)
            const Center(child: CircularProgressIndicator())
          else
            DropdownButtonFormField<Doctor>(
              value: _selectedDoctor,
              decoration: InputDecoration(
                labelText: 'ډاکټر غوره کړئ',
                labelStyle: GoogleFonts.cairo(),
              ),
              items: _doctors.map((d) => DropdownMenuItem(
                value: d,
                child: Text(d.name, style: GoogleFonts.cairo(),
                    textDirection: TextDirection.rtl),
              )).toList(),
              onChanged: (d) => setState(() => _selectedDoctor = d),
            ),
          if (_selectedDoctor != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('پخوانی پاتې: ${Fmt.money(_selectedDoctor!.balance)}',
                      style: GoogleFonts.cairo(
                          color: AppTheme.primary, fontWeight: FontWeight.w600),
                      textDirection: TextDirection.rtl),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: PS.paymentAmount,
              labelStyle: GoogleFonts.cairo(),
              prefixIcon: const Icon(Icons.attach_money),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              labelText: PS.notes,
              labelStyle: GoogleFonts.cairo(),
              prefixIcon: const Icon(Icons.note),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: _saving
                ? const SizedBox(height: 20, width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(PS.recordPayment,
                    style: GoogleFonts.cairo(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
