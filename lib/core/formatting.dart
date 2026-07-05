import 'package:intl/intl.dart';

import 'currency.dart';

final _dateFormat = DateFormat('dd/MM/yyyy');
final _monthYearFormat = DateFormat('MMMM yyyy', 'es');

String formatCurrency(double amount, AppCurrency currency) {
  final format = NumberFormat.currency(
    locale: currency.locale,
    symbol: currency.symbol,
  );
  return format.format(amount);
}

String formatDate(DateTime date) => _dateFormat.format(date);

String formatMonthYear(DateTime date) => _monthYearFormat.format(date);
