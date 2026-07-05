import 'package:flutter/material.dart';

/// Mapea claves de texto (persistidas en la base de datos) a [IconData].
/// Las categorías guardan la clave en vez del icono directamente para que
/// sea serializable y estable entre versiones de la app.
const Map<String, IconData> kIconMap = {
  // ingresos
  'work': Icons.work,
  'laptop': Icons.laptop_mac,
  'storefront': Icons.storefront,
  'percent': Icons.percent,
  'card_giftcard': Icons.card_giftcard,
  'redeem': Icons.redeem,
  'replay': Icons.replay,
  'sell': Icons.sell,
  'category': Icons.category,

  // vivienda / servicios
  'home': Icons.home,
  'house': Icons.house,
  'build': Icons.build,
  'handyman': Icons.handyman,
  'bolt': Icons.bolt,
  'water_drop': Icons.water_drop,
  'wifi': Icons.wifi,
  'phone': Icons.phone,
  'tv': Icons.tv,

  // alimentacion
  'shopping_cart': Icons.shopping_cart,
  'restaurant': Icons.restaurant,
  'delivery_dining': Icons.delivery_dining,
  'cookie': Icons.cookie,

  // transporte
  'local_gas_station': Icons.local_gas_station,
  'local_taxi': Icons.local_taxi,
  'directions_bus': Icons.directions_bus,
  'directions_car': Icons.directions_car,

  // salud
  'medication': Icons.medication,
  'medical_services': Icons.medical_services,
  'health_and_safety': Icons.health_and_safety,

  // educacion
  'school': Icons.school,
  'menu_book': Icons.menu_book,
  'workspace_premium': Icons.workspace_premium,

  // entretenimiento
  'movie': Icons.movie,
  'sports_esports': Icons.sports_esports,
  'theater_comedy': Icons.theater_comedy,
  'event': Icons.event,

  // compras
  'checkroom': Icons.checkroom,
  'devices': Icons.devices,
  'chair': Icons.chair,
  'watch': Icons.watch,

  // finanzas
  'request_quote': Icons.request_quote,
  'credit_card': Icons.credit_card,
  'trending_down': Icons.trending_down,

  // otros / general
  'more_horiz': Icons.more_horiz,
  'savings': Icons.savings,
  'flight': Icons.flight,
  'directions_car_filled': Icons.directions_car_filled,
  'computer': Icons.computer,
  'account_balance_wallet': Icons.account_balance_wallet,
  'account_balance': Icons.account_balance,
};

IconData iconForKey(String key) => kIconMap[key] ?? Icons.category;
