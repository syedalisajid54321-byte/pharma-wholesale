// lib/utils/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF1A5276);
  static const Color primaryDark = Color(0xFF0E3A56);
  static const Color accent = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFE67E22);
  static const Color danger = Color(0xFFE74C3C);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      textTheme: GoogleFonts.notoNastaliqUrduTextTheme().copyWith(
        headlineLarge: GoogleFonts.cairo(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.cairo(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.cairo(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.cairo(
          fontSize: 16,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.cairo(
          fontSize: 14,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ─── Pashto / Dari Strings ───────────────────────────────────────────────────
class PS {
  // App
  static const appName = 'دواخانه ولسي سیستم';
  static const appSubtitle = 'د دوایو تولپلورنې مدیریت';

  // Navigation
  static const home = 'کور';
  static const doctors = 'ډاکټران';
  static const invoices = 'بیل';
  static const payments = 'ادایيګي';
  static const ledger = 'حساب کتاب';
  static const reports = 'راپورونه';
  static const settings = 'ترتیبات';

  // Doctor
  static const doctorName = 'د ډاکټر نوم';
  static const doctorPhone = 'د ډاکټر ټیلفون';
  static const doctorAddress = 'د ډاکټر پته';
  static const addDoctor = 'ډاکټر اضافه کړئ';
  static const editDoctor = 'ډاکټر سم کړئ';
  static const deleteDoctor = 'ډاکټر حذف کړئ';
  static const noDoctors = 'هیڅ ډاکټر نه دی';
  static const searchDoctors = 'ډاکټر لټوئ...';

  // Invoice
  static const invoiceAmount = 'د بیل مقدار';
  static const invoiceDate = 'د بیل نیټه';
  static const invoiceNumber = 'د بیل نمبر';
  static const createInvoice = 'بیل جوړ کړئ';
  static const notes = 'یادداشتونه';

  // Payment
  static const paymentAmount = 'د ادایيګۍ مقدار';
  static const paymentDate = 'د ادایيګۍ نیټه';
  static const receiptNumber = 'د رسید نمبر';
  static const recordPayment = 'ادایيګي ثبت کړئ';

  // Balance
  static const previousBalance = 'پخوانی پاتې';
  static const currentBalance = 'اوسنی پاتې';
  static const totalReceivable = 'ټول وصولۍ';
  static const totalPayments = 'ټول ادایيګي';
  static const outstandingBalance = 'پاتې قرض';

  // Actions
  static const save = 'خوندي کړئ';
  static const cancel = 'لغوه کړئ';
  static const delete = 'حذف کړئ';
  static const confirm = 'تایید کړئ';
  static const edit = 'سم کړئ';
  static const search = 'لټون';

  // Reports
  static const dailyReport = 'ورځنۍ راپور';
  static const monthlyReport = 'میاشتنۍ راپور';
  static const doctorStatement = 'د ډاکټر حساب';
  static const totalSummary = 'ټول لنډیز';

  // Login
  static const login = 'ننوتل';
  static const email = 'بریښنالیک';
  static const password = 'پټنوم';
  static const loginBtn = 'ننوتل';
  static const logout = 'وتل';

  // Messages
  static const confirmDelete = 'ایا غواړئ حذف کړئ؟';
  static const deleteWarning = 'دا کړنه بیرته نه شي کیدلای';
  static const success = 'بریالی!';
  static const error = 'تیروتنه';
  static const loading = 'انتظار وکړئ...';
}
