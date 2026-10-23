import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:wms/stackup/app.dart';
import 'package:wms/stackup/domain.dart';
import 'package:wms/stackup/store.dart';

class MemoryDatabase extends Fake implements Database {
  final Map<String, Object?> values = {};
  @override
  Future<int> insert(
    String table,
    Map<String, Object?> data, {
    String? nullColumnHack,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    values[data['key'] as String] = data['value'];
    return 1;
  }
}

void main() {
  setUpAll(() async {
    var sdk = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 5; i++) {
      sdk = sdk.parent;
    }
    final root = Platform.environment['FLUTTER_ROOT'] ?? sdk.path;
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    }.entries) {
      final file = File(
        '$root/bin/cache/artifacts/material_fonts/${entry.value}',
      );
      if (await file.exists()) {
        final loader = FontLoader(entry.key)
          ..addFont(file.readAsBytes().then((b) => ByteData.sublistView(b)));
        await loader.load();
      }
    }
  });
  Future<WarehouseStore> launch(
    WidgetTester tester, {
    bool admin = false,
    Size size = const Size(390, 844),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = WarehouseStore.forTest(MemoryDatabase(), Warehouse.demo());
    store.role = admin ? AppRole.admin : AppRole.worker;
    await tester.pumpWidget(StackUpApp(store: store));
    await tester.pumpAndSettle();
    return store;
  }

  Future<void> shot(WidgetTester tester, String name) async {
    final boundary = tester.firstRenderObject<RenderRepaintBoundary>(
      find.byType(RepaintBoundary),
    );
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await Directory('build/ui-preview').create(recursive: true);
      await File(
        'build/ui-preview/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets('trabajador no ve admin y puede elegir cualquier ruta', (
    tester,
  ) async {
    await launch(tester);
    expect(find.text('Admin'), findsNothing);
    await shot(tester, '01-inicio');
    expect(find.byType(NavigationBar), findsNothing);
    await tester.pumpAndSettle();
    for (final v in ['CAM102', 'CAM105', 'CAM108']) {
      expect(find.text(v), findsOneWidget);
    }
    expect(find.textContaining('Cuadre parcial'), findsNothing);
    await shot(tester, '02-rutas');
    await tester.tap(find.text('CAM105'));
    await tester.pumpAndSettle();
    await shot(tester, '03-pedidos');
    await tester.tap(find.text('10668482 · Lote 19'));
    await tester.pumpAndSettle();
    expect(find.text('Corregir ubicación / revisión'), findsNothing);
    await shot(tester, '04-ubicaciones');
    expect(tester.takeException(), isNull);
  });
  testWidgets('cuadrar rechaza otra ruta y termina sin estado parcial', (
    tester,
  ) async {
    final store = await launch(tester);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CAM105'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuadrar ruta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('scanner-input')),
      store.data.orders.first.barcode,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.textContaining('Caja de otro vehículo'), findsOneWidget);
    expect(store.data.total('verified'), 0);
    await shot(tester, '05-aviso-cuadre');
    final codes = [
      for (final o in store.data.route('CAM105'))
        for (var i = 0; i < o.expected; i++) o.barcode,
    ];
    for (final code in codes) {
      await tester.enterText(find.byKey(const ValueKey('scanner-input')), code);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
    }
    expect(store.data.complete('CAM105'), true);
    expect(find.text('Ruta cuadrada'), findsOneWidget);
    await shot(tester, '06-cuadrada');
    expect(tester.takeException(), isNull);
  });
  testWidgets('admin y recepción se adaptan a teléfono pequeño', (
    tester,
  ) async {
    await launch(tester, admin: true, size: const Size(360, 740));
    await tester.tap(find.text('Admin').last);
    await tester.pumpAndSettle();
    await shot(tester, '07-admin');
    await tester.scrollUntilVisible(
      find.text('Registrar cajas'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Registrar cajas'));
    await tester.pumpAndSettle();
    await shot(tester, '08-recepcion');
    expect(tester.takeException(), isNull);
  });
  test('el modelo bloquea mutaciones administrativas del trabajador', () async {
    final store = WarehouseStore.forTest(MemoryDatabase(), Warehouse.demo());
    store.loginWorker();
    await expectLater(
      store.change((w) => w.orders.clear(), adminOnly: true),
      throwsA(isA<WarehouseError>()),
    );
    await expectLater(
      store.reset(Warehouse.empty()),
      throwsA(isA<WarehouseError>()),
    );
    expect(store.data.orders.length, 100);
  });
}
