import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:finanzas360/core/database/app_database.dart';
import 'package:finanzas360/core/database/database_provider.dart';
import 'package:finanzas360/main.dart';

void main() {
  testWidgets('App carga el dashboard sin excepciones', (tester) async {
    await initializeDateFormatting('es');
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MyApp(),
      ),
    );
    // No se usa pumpAndSettle: los streams de Drift quedan activos
    // indefinidamente (watch()), por lo que nunca "se asientan".
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Dashboard'), findsOneWidget);

    // Desmontar el árbol explícitamente y dejar correr un frame mas: así el
    // timer de cierre que Drift crea al cancelar el stream (en el dispose
    // del ProviderScope) se ejecuta antes de que el test termine, evitando
    // el assert "timersPending" de flutter_test.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 500));
  });
}
