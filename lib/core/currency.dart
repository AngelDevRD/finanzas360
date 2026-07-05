import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Monedas soportadas por la app. Cada una trae su símbolo y el locale de
/// intl que define el formato de separadores/decimales correcto.
enum AppCurrency {
  usd('USD', '\$', 'en_US'),
  dop('DOP', 'RD\$', 'es_DO'),
  eur('EUR', '€', 'es_ES');

  const AppCurrency(this.code, this.symbol, this.locale);

  final String code;
  final String symbol;
  final String locale;

  String get label => '$code  ($symbol)';
}

const _currencyPrefsKey = 'app_currency';

class CurrencyController extends Notifier<AppCurrency> {
  @override
  AppCurrency build() {
    _loadSaved();
    return AppCurrency.dop;
  }

  Future<void> _loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_currencyPrefsKey);
    if (saved == null) return;
    state = AppCurrency.values.firstWhere(
      (c) => c.code == saved,
      orElse: () => AppCurrency.dop,
    );
  }

  Future<void> setCurrency(AppCurrency currency) async {
    state = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyPrefsKey, currency.code);
  }
}

final currencyProvider = NotifierProvider<CurrencyController, AppCurrency>(
  CurrencyController.new,
);
