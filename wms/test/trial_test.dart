import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wms/stackup/app.dart';
import 'package:wms/stackup/domain.dart';
import 'package:wms/stackup/store.dart';
import 'screens_test.dart' show MemoryDatabase;

void main() {
  testWidgets('15 lecturas con Enter exigen nueva zona sin botones', (
    tester,
  ) async {
    final w = Warehouse.empty()
      ..orders.add(
        Order(
          guide: '12',
          contact: '34',
          name: 'Prueba',
          vehicle: 'CAM1',
          lot: 19,
          expected: 20,
        ),
      );
    final store = WarehouseStore.forTest(MemoryDatabase(), w)
      ..role = AppRole.admin;
    await tester.pumpWidget(MaterialApp(home: ScanPage(store: store)));
    await tester.pumpAndSettle();
    Future<void> scan(String code) async {
      await tester.enterText(find.byKey(const ValueKey('scanner-input')), code);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }

    await scan('Z:A-01');
    for (var i = 0; i < 15; i++) {
      await scan('34F12');
    }
    expect(find.text('Esperando zona'), findsOneWidget);
    expect(store.data.zoneCount('A-01'), 15);
    await scan('34F12');
    expect(store.data.total('received'), 15);
    await scan('Z:A-01');
    expect(store.data.total('received'), 15);
    await scan('Z:A-02');
    await scan('34F12');
    expect(store.data.zoneCount('A-02'), 1);
    expect(find.text('Registrar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('buscador dentro del vehiculo excluye pedidos ajenos', (
    tester,
  ) async {
    final store = WarehouseStore.forTest(MemoryDatabase(), Warehouse.demo())
      ..role = AppRole.worker;
    await tester.pumpWidget(StackUpApp(store: store));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Consultas'), findsNothing);
    await tester.tap(find.text('CAM105'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('route-search')),
      '10668481',
    );
    await tester.pumpAndSettle();
    expect(find.byType(OrderTile), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('route-search')),
      '10668482',
    );
    await tester.pumpAndSettle();
    expect(find.byType(OrderTile), findsOneWidget);
    expect(find.textContaining('A-01:'), findsOneWidget);
  });
  testWidgets('consultas admin muestra estados sin duplicar revision', (
    tester,
  ) async {
    final w = Warehouse.demo();
    final store = WarehouseStore.forTest(MemoryDatabase(), w)
      ..role = AppRole.admin;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: SearchPage(store: store)),
      ),
    );
    await tester.pumpAndSettle();
    expect(w.orders.first.awaiting, 1);
    expect(w.orders.first.review, 1);
    expect(find.byType(StatusCounts), findsWidgets);
    expect(find.text('1 en revisión'), findsOneWidget);
  });
}
