// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/doctor.dart';
import '../services/firebase_service.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _svc = FirebaseService();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(PS.reports),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'لنډیز'),
            Tab(text: 'ورځنۍ'),
            Tab(text: 'میاشتنۍ'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _SummaryTab(svc: _svc),
          _DailyReportTab(svc: _svc),
          _MonthlyReportTab(svc: _svc),
        ],
      ),
    );
  }
}

// ─── Summary Tab ─────────────────────────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  final FirebaseService svc;
  const _SummaryTab({required this.svc});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Doctor>>(
      stream: svc.watchDoctors(),
      builder: (context, snap) {
        final doctors = snap.data ?? [];
        final totalReceivable =
            doctors.fold(0.0, (s, d) => s + (d.balance > 0 ? d.balance : 0));
        final totalAdvance =
            doctors.fold(0.0, (s, d) => s + (d.balance < 0 ? d.balance.abs() : 0));
        final debtors = doctors.where((d) => d.balance > 0).toList()
          ..sort((a, b) => b.balance.compareTo(a.balance));

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary cards
              Row(children: [
                Expanded(child: _StatCard(
                  label: 'ټول ډاکټران', value: '${doctors.length}',
                  icon: Icons.people, color: AppTheme.primary,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'قرض لرونکي', value: '${debtors.length}',
                  icon: Icons.warning, color: AppTheme.danger,
                )),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _StatCard(
                  label: 'ټول وصولۍ',
                  value: Fmt.money(totalReceivable),
                  icon: Icons.account_balance,
                  color: AppTheme.warning,
                  small: true,
                )),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(
                  label: 'زیات ورکړل',
                  value: Fmt.money(totalAdvance),
                  icon: Icons.savings,
                  color: AppTheme.accent,
                  small: true,
                )),
              ]),

              const SizedBox(height: 24),

              // Pie chart if there are debtors
              if (debtors.isNotEmpty) ...[
                Text('د قرض ویش', style: GoogleFonts.cairo(
                    fontSize: 18, fontWeight: FontWeight.w700),
                    textDirection: TextDirection.rtl, textAlign: TextAlign.right),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: PieChart(PieChartData(
                    sections: debtors.take(6).toList().asMap().entries.map((e) {
                      final colors = [
                        AppTheme.primary, AppTheme.danger, AppTheme.warning,
                        AppTheme.accent, Colors.purple, Colors.teal,
                      ];
                      return PieChartSectionData(
                        value: e.value.balance,
                        title: e.value.name.length > 8
                            ? '${e.value.name.substring(0, 8)}...'
                            : e.value.name,
                        color: colors[e.key % colors.length],
                        radius: 80,
                        titleStyle: GoogleFonts.cairo(
                            fontSize: 10, color: Colors.white,
                            fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  )),
                ),
                const SizedBox(height: 24),
              ],

              // Top debtors list
              Text('د قرض لرونکو لیست',
                  style: GoogleFonts.cairo(
                      fontSize: 18, fontWeight: FontWeight.w700),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right),
              const SizedBox(height: 12),
              ...debtors.map((d) => _DebtorRow(doctor: d)),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool small;

  const _StatCard({
    required this.label, required this.value,
    required this.icon, required this.color, this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.cairo(
                    fontSize: small ? 13 : 24,
                    fontWeight: FontWeight.w800, color: color),
                textAlign: TextAlign.right),
            Text(label,
                style: GoogleFonts.cairo(
                    color: AppTheme.textSecondary, fontSize: 12),
                textDirection: TextDirection.rtl, textAlign: TextAlign.right),
          ],
        ),
      ),
    );
  }
}

class _DebtorRow extends StatelessWidget {
  final Doctor doctor;
  const _DebtorRow({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Text(Fmt.money(doctor.balance),
                style: GoogleFonts.cairo(
                    color: AppTheme.danger, fontWeight: FontWeight.w700,
                    fontSize: 14)),
            Expanded(
              child: Text(doctor.name,
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.w600, fontSize: 15),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily Report Tab ────────────────────────────────────────────────────────
class _DailyReportTab extends StatefulWidget {
  final FirebaseService svc;
  const _DailyReportTab({required this.svc});

  @override
  State<_DailyReportTab> createState() => _DailyReportTabState();
}

class _DailyReportTabState extends State<_DailyReportTab> {
  DateTime _date = DateTime.now();
  Map<String, dynamic>? _report;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await widget.svc.getDailyReport(_date);
      if (mounted) setState(() { _report = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Date picker
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: AppTheme.primary),
              title: Text(Fmt.date(_date),
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w600)),
              subtitle: Text('نیټه غوره کړئ',
                  style: GoogleFonts.cairo(fontSize: 12)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                  _load();
                }
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_report != null) ...[
            _ReportCard(label: 'بیلونه', count: _report!['invoiceCount'],
                amount: _report!['totalInvoices'], color: AppTheme.warning),
            const SizedBox(height: 12),
            _ReportCard(label: 'ادایيګي', count: _report!['paymentCount'],
                amount: _report!['totalPayments'], color: AppTheme.accent),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('خالص', style: GoogleFonts.cairo(
                        fontSize: 16, fontWeight: FontWeight.w700),
                        textDirection: TextDirection.rtl),
                    const SizedBox(height: 8),
                    Text(
                      Fmt.money((_report!['totalInvoices'] as double) -
                          (_report!['totalPayments'] as double)),
                      style: GoogleFonts.cairo(
                          fontSize: 22, fontWeight: FontWeight.w800,
                          color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Monthly Report Tab ───────────────────────────────────────────────────────
class _MonthlyReportTab extends StatefulWidget {
  final FirebaseService svc;
  const _MonthlyReportTab({required this.svc});

  @override
  State<_MonthlyReportTab> createState() => _MonthlyReportTabState();
}

class _MonthlyReportTabState extends State<_MonthlyReportTab> {
  DateTime _month = DateTime.now();
  Map<String, dynamic>? _report;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await widget.svc.getMonthlyReport(_month.year, _month.month);
      if (mounted) setState(() { _report = r; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      onPressed: () => _changeMonth(1),
                      icon: const Icon(Icons.chevron_left)),
                  Text(Fmt.month(_month),
                      style: GoogleFonts.cairo(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                  IconButton(
                      onPressed: () => _changeMonth(-1),
                      icon: const Icon(Icons.chevron_right)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_report != null) ...[
            _ReportCard(label: 'بیلونه', count: _report!['invoiceCount'],
                amount: _report!['totalInvoices'], color: AppTheme.warning),
            const SizedBox(height: 12),
            _ReportCard(label: 'ادایيګي', count: _report!['paymentCount'],
                amount: _report!['totalPayments'], color: AppTheme.accent),
            const SizedBox(height: 12),
            // Bar chart
            if ((_report!['invoiceCount'] as int) > 0 ||
                (_report!['paymentCount'] as int) > 0) ...[
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 180,
                    child: BarChart(BarChartData(
                      barGroups: [
                        BarChartGroupData(x: 0, barRods: [
                          BarChartRodData(
                              toY: (_report!['totalInvoices'] as double),
                              color: AppTheme.warning, width: 40,
                              borderRadius: BorderRadius.circular(6)),
                        ]),
                        BarChartGroupData(x: 1, barRods: [
                          BarChartRodData(
                              toY: (_report!['totalPayments'] as double),
                              color: AppTheme.accent, width: 40,
                              borderRadius: BorderRadius.circular(6)),
                        ]),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Text(
                              v == 0 ? 'بیلونه' : 'ادایيګي',
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                    )),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final int count;
  final double amount;
  final Color color;

  const _ReportCard({
    required this.label, required this.count,
    required this.amount, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$count', style: GoogleFonts.cairo(
                  fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              Text('شمیر', style: GoogleFonts.cairo(
                  color: AppTheme.textSecondary, fontSize: 12)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(label, style: GoogleFonts.cairo(
                  fontSize: 16, fontWeight: FontWeight.w700),
                  textDirection: TextDirection.rtl),
              const SizedBox(height: 4),
              Text(Fmt.money(amount), style: GoogleFonts.cairo(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color)),
            ]),
          ],
        ),
      ),
    );
  }
}
