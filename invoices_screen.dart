// lib/screens/invoices_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/doctor.dart';
import '../models/invoice.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class InvoicesScreen extends StatelessWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: Text(PS.invoices)),
      body: StreamBuilder<List<Invoice>>(
        stream: svc.watchAllInvoices(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final invoices = snap.data ?? [];

          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('هیڅ بیل نه دی',
                      style: GoogleFonts.cairo(
                          color: AppTheme.textSecondary, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: invoices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _InvoiceTile(invoice: invoices[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateInvoice(context, svc),
        icon: const Icon(Icons.add),
        label: Text(PS.createInvoice, style: GoogleFonts.cairo()),
      ),
    );
  }

  void _showCreateInvoice(BuildContext context, FirebaseService svc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _CreateInvoiceForm(svc: svc),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceTile({required this.invoice});

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
                    color: AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    invoice.invoiceNumber,
                    style: GoogleFonts.cairo(
                      color: AppTheme.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  invoice.doctorName,
                  style: GoogleFonts.cairo(
                      fontSize: 16, fontWeight: FontWeight.w700),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _row('مقدار', Fmt.money(invoice.amount),
                valueColor: AppTheme.danger),
            _row('پخوانی پاتې', Fmt.money(invoice.previousBalance)),
            _row('نوی پاتې', Fmt.money(invoice.newBalance),
                valueColor: AppTheme.primary),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Fmt.date(invoice.date),
                  style: GoogleFonts.cairo(
                      color: AppTheme.textSecondary, fontSize: 12),
                ),
                if (invoice.notes.isNotEmpty)
                  Text(
                    invoice.notes,
                    style: GoogleFonts.cairo(
                        color: AppTheme.textSecondary, fontSize: 12),
                    textDirection: TextDirection.rtl,
                  ),
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
          Text(
            value,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
          Text(label,
              style:
                  GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 13),
              textDirection: TextDirection.rtl),
        ],
      ),
    );
  }
}

class _CreateInvoiceForm extends StatefulWidget {
  final FirebaseService svc;
  const _CreateInvoiceForm({required this.svc});

  @override
  State<_CreateInvoiceForm> createState() => _CreateInvoiceFormState();
}

class _CreateInvoiceFormState extends State<_CreateInvoiceForm> {
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
      await widget.svc.createInvoice(
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
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text(PS.createInvoice,
              style: GoogleFonts.cairo(
                  fontSize: 20, fontWeight: FontWeight.w700),
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
              items: _doctors.map((d) {
                return DropdownMenuItem(
                  value: d,
                  child: Text(d.name, style: GoogleFonts.cairo(),
                      textDirection: TextDirection.rtl),
                );
              }).toList(),
              onChanged: (d) => setState(() => _selectedDoctor = d),
            ),
          if (_selectedDoctor != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'پخوانی پاتې: ${Fmt.money(_selectedDoctor!.balance)}',
                style: GoogleFonts.cairo(
                    color: AppTheme.primary, fontWeight: FontWeight.w600),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: PS.invoiceAmount,
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
            child: _saving
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(PS.createInvoice,
                    style: GoogleFonts.cairo(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
