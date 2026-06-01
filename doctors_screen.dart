// lib/screens/doctors_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/doctor.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'ledger_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final _svc = FirebaseService();
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(PS.doctors),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              textDirection: TextDirection.rtl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: PS.searchDoctors,
                hintStyle: GoogleFonts.cairo(),
                prefixIcon: const Icon(Icons.search),
                fillColor: Colors.white,
                filled: true,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Doctor>>(
        stream: _svc.watchDoctors(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snap.data ?? [];
          final doctors = _search.isEmpty
              ? all
              : all
                  .where((d) =>
                      d.name.contains(_search) ||
                      d.phone.contains(_search) ||
                      d.address.contains(_search))
                  .toList();

          if (doctors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(PS.noDoctors,
                      style: GoogleFonts.cairo(
                          color: AppTheme.textSecondary, fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: doctors.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _DoctorTile(
              doctor: doctors[i],
              onEdit: () => _showDoctorForm(doctor: doctors[i]),
              onDelete: () => _confirmDelete(doctors[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDoctorForm(),
        icon: const Icon(Icons.add),
        label: Text(PS.addDoctor, style: GoogleFonts.cairo()),
      ),
    );
  }

  void _showDoctorForm({Doctor? doctor}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DoctorForm(doctor: doctor, svc: _svc),
    );
  }

  void _confirmDelete(Doctor doctor) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(PS.deleteDoctor, style: GoogleFonts.cairo()),
        content: Text('${PS.confirmDelete}\n${PS.deleteWarning}',
            style: GoogleFonts.cairo(), textDirection: TextDirection.rtl),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(PS.cancel, style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _svc.deleteDoctor(doctor.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: Text(PS.delete, style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DoctorTile({
    required this.doctor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: PS.edit,
          ),
          SlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: PS.delete,
          ),
        ],
      ),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LedgerScreen(doctor: doctor)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        doctor.name,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            doctor.phone,
                            style: GoogleFonts.cairo(
                                color: AppTheme.textSecondary, fontSize: 13),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.phone,
                              size: 14, color: AppTheme.textSecondary),
                        ],
                      ),
                      if (doctor.address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              doctor.address,
                              style: GoogleFonts.cairo(
                                  color: AppTheme.textSecondary, fontSize: 12),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.location_on,
                                size: 13, color: AppTheme.textSecondary),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: doctor.balance > 0
                            ? AppTheme.danger.withOpacity(0.1)
                            : doctor.balance < 0
                                ? AppTheme.accent.withOpacity(0.1)
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        Fmt.money(doctor.balance.abs()),
                        style: GoogleFonts.cairo(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: doctor.balance > 0
                              ? AppTheme.danger
                              : doctor.balance < 0
                                  ? AppTheme.accent
                                  : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      doctor.balance > 0
                          ? 'قرض'
                          : doctor.balance < 0
                              ? 'زیات'
                              : 'پاک',
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_left, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DoctorForm extends StatefulWidget {
  final Doctor? doctor;
  final FirebaseService svc;

  const _DoctorForm({this.doctor, required this.svc});

  @override
  State<_DoctorForm> createState() => _DoctorFormState();
}

class _DoctorFormState extends State<_DoctorForm> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.doctor?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.doctor?.phone ?? '');
    _addressCtrl = TextEditingController(text: widget.doctor?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      if (widget.doctor == null) {
        await widget.svc.addDoctor(Doctor(
          id: '',
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          createdAt: DateTime.now(),
        ));
      } else {
        await widget.svc.updateDoctor(widget.doctor!.copyWith(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
        ));
      }
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
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.doctor == null ? PS.addDoctor : PS.editDoctor,
            style: GoogleFonts.cairo(
                fontSize: 20, fontWeight: FontWeight.w700),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          const SizedBox(height: 20),
          _field(_nameCtrl, PS.doctorName, Icons.person),
          const SizedBox(height: 12),
          _field(_phoneCtrl, PS.doctorPhone, Icons.phone,
              type: TextInputType.phone),
          const SizedBox(height: 12),
          _field(_addressCtrl, PS.doctorAddress, Icons.location_on),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : Text(PS.save, style: GoogleFonts.cairo(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.cairo(),
        prefixIcon: Icon(icon),
      ),
    );
  }
}
