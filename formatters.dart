// lib/utils/formatters.dart
import 'package:intl/intl.dart';

class Fmt {
  static final _currency = NumberFormat('#,##0.00', 'en_US');
  static final _date = DateFormat('dd/MM/yyyy');
  static final _dateTime = DateFormat('dd/MM/yyyy  HH:mm');
  static final _month = DateFormat('MMMM yyyy');

  static String money(double amount) => 'AFN ${_currency.format(amount)}';
  static String date(DateTime dt) => _date.format(dt);
  static String dateTime(DateTime dt) => _dateTime.format(dt);
  static String month(DateTime dt) => _month.format(dt);

  static String balanceLabel(double balance) {
    if (balance > 0) return 'قرض: ${money(balance)}';
    if (balance < 0) return 'زیات ورکړل شو: ${money(balance.abs())}';
    return 'پاک حساب';
  }
}
