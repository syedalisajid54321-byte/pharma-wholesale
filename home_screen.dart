// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/doctor.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import 'doctors_screen.dart';
import 'invoices_screen.dart';
import 'payments_screen.dart';
import 'reports_screen.dart';
import 'ledger_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _svc = FirebaseService();
  int _currentIndex = 0;

  final _screens = const [
    _DashboardTab(),
    DoctorsScreen(),
    InvoicesScreen(),
    PaymentsScreen(),
    ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.primary.withOpacity(0.15),
        destinations: [
          _navDest(Icons.dashboard, PS.home),
          _navDest(Icons.people, PS.doctors),
          _navDest(Icons.receipt_long, PS.invoices),
          _navDest(Icons.payments, PS.payments),
          _navDest(Icons.bar_chart, PS.reports),
        ],
      ),
    );
  }

  NavigationDestination _navDest(IconData icon, String label) {
    return NavigationDestination(
      icon: Icon(icon),
      label: label,
      selectedIcon: Icon(icon, color: AppTheme.primary),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final svc = FirebaseService();

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(PS.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => svc.signOut(),
            tooltip: PS.logout,
          ),
        ],
      ),
      body: StreamBuilder<List<Doctor>>(
        stream: svc.watchDoctors(),
        builder: (context, snap) {
          final doctors = snap.data ?? [];
          final totalReceivable =
              doctors.fold(0.0, (sum, d) => sum + (d.balance > 0 ? d.balance : 0));
          final totalAdvance =
              doctors.fold(0.0, (sum, d) => sum + (d.balance < 0 ? d.balance.abs() : 0));

          return RefreshIndicator(
            onRefresh: () async {},
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'ټول ډاکټران',
                          value: '${doctors.length}',
                          icon: Icons.people,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: PS.totalReceivable,
                          value: Fmt.money(totalReceivable),
                          icon: Icons.account_balance_wallet,
                          color: AppTheme.warning,
                          isAmount: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'د قرض ډاکټران',
                          value: '${doctors.where((d) => d.balance > 0).length}',
                          icon: Icons.warning_amber,
                          color: AppTheme.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'پاک حساب',
                          value: '${doctors.where((d) => d.balance == 0).length}',
                          icon: Icons.check_circle,
                          color: AppTheme.accent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _sectionHeader('د قرض لرونکي ډاکټران'),
                  const SizedBox(height: 12),

                  // Top debtors
                  if (doctors.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(PS.noDoctors,
                            style: GoogleFonts.cairo(color: AppTheme.textSecondary)),
                      ),
                    )
                  else
                    ...doctors
                        .where((d) => d.balance > 0)
                        .toList()
                      ..sort((a, b) => b.balance.compareTo(a.balance))
                      ..take(10).map((d) => _DoctorBalanceCard(doctor: d)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Text(
        title,
        style: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isAmount;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isAmount = false,
  });

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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.cairo(
                fontSize: isAmount ? 13 : 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorBalanceCard extends StatelessWidget {
  final Doctor doctor;
  const _DoctorBalanceCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primary,
          child: Text(
            doctor.name.isNotEmpty ? doctor.name[0] : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          doctor.name,
          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          textDirection: TextDirection.rtl,
        ),
        subtitle: Text(
          doctor.phone,
          style: GoogleFonts.cairo(color: AppTheme.textSecondary, fontSize: 13),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              Fmt.money(doctor.balance),
              style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: doctor.balance > 0 ? AppTheme.danger : AppTheme.accent,
              ),
            ),
            Text(
              doctor.balance > 0 ? 'قرض' : 'پاک',
              style: GoogleFonts.cairo(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LedgerScreen(doctor: doctor),
            ),
          );
        },
      ),
    );
  }
}
