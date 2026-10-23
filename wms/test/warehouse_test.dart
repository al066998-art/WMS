import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:excel/excel.dart';
import 'package:wms/stackup/domain.dart';
import 'package:wms/stackup/importer.dart';

void main() {
  group('Demostración ampliada y lotes por ruta', () {
    test(
      '350 cajas, 100 pedidos, 10 rutas de un solo lote y zonas consecutivas',
      () {
        final w = Warehouse.demo();
        expect(w.orders.length, 100);
        expect(w.vehicles.length, 10);
        expect(w.total('expected'), 350);
        expect(w.total('received'), 350);
        expect(w.total('received', lot: 19), 210);
        expect(w.total('received', lot: 22), 140);
        expect(w.total('review'), 1);
        expect(w.total('special'), 10);
        for (final v in w.vehicles) {
          expect(w.route(v).map((o) => o.lot).toSet().length, 1);
        }
        final normal = w.zones.where((z) => z.kind == 'normal').toList();
        expect(normal.length, 24);
        for (var i = 0; i < normal.length; i++) {
          final z = normal[i];
          expect(w.zoneCount(z.code), inInclusiveRange(1, 15));
          final lots = w.orders
              .where((o) => o.locations.containsKey(z.code))
              .map((o) => o.lot)
              .toSet();
          expect(lots, {i < 14 ? 19 : 22});
        }
        expect(w.orders.any((o) => o.locations.length > 1), true);
        final empty = Warehouse.demo(received: false);
        expect(empty.total('received'), 0);
        expect(empty.total('expected'), 350);
        expect(empty.zones.map((z) => z.code), w.zones.map((z) => z.code));
      },
    );
    test(
      'importar otro lote con el mismo vehículo falla sin cambiar datos',
      () {
        final w = Warehouse.empty();
        Order order(int lot, String vehicle) => Order(
          guide: '$lot',
          contact: '$lot',
          name: 'Prueba',
          vehicle: vehicle,
          lot: lot,
          expected: 2,
        );
        w.importLot([order(19, 'CAM102')], 19);
        final before = w.toJson().toString();
        expect(
          () => w.importLot([order(22, ' cam102 ')], 22),
          throwsA(isA<WarehouseError>()),
        );
        expect(w.toJson().toString(), before);
        w.importLot([order(22, 'CAM105')], 22);
        expect(w.orders.length, 2);
        // Una campaña nueva puede usar el mismo vehículo para el otro lote.
        final next = Warehouse.empty();
        next.importLot([order(22, 'CAM102')], 22);
        expect(next.route('CAM102').single.lot, 22);
      },
    );
  });
  group('Recepción y cuadre', () {
    test('zona general admite 15 entre ambos lotes', () {
      final w = Warehouse.empty();
      for (final lot in [19, 22]) {
        w.orders.add(
          Order(
            guide: '$lot',
            contact: '$lot',
            name: 'Prueba',
            vehicle: 'CAM1',
            lot: lot,
            expected: 20,
          ),
        );
      }
      for (var i = 0; i < 8; i++) {
        w.receive(w.orders[0].barcode, 'A-01');
      }
      for (var i = 0; i < 7; i++) {
        w.receive(w.orders[1].barcode, 'A-01');
      }
      expect(w.zoneCount('A-01'), 15);
      expect(
        () => w.receive(w.orders[1].barcode, 'A-01'),
        throwsA(isA<WarehouseError>()),
      );
      expect(w.total('received'), 15);
      w.receive(w.orders[1].barcode, 'A-02');
      expect(w.zoneCount('A-02'), 1);
    });
    test('especiales y revision sin limite de 15', () {
      for (final zone in ['ES-19', 'ES-22', 'REVISION']) {
        final w = Warehouse.empty();
        w.orders.add(
          Order(
            guide: '1',
            contact: '1',
            name: 'Prueba',
            vehicle: 'CAM1',
            lot: 19,
            expected: 20,
          ),
        );
        for (var i = 0; i < 20; i++) {
          w.receive(w.orders.first.barcode, zone);
        }
        expect(w.zoneCount(zone), 20);
        expect(w.zoneFull(zone), false);
      }
    });
    test('correccion respeta capacidad de destino', () {
      final w = Warehouse.empty();
      w.orders.add(
        Order(
          guide: '1',
          contact: '1',
          name: 'Prueba',
          vehicle: 'CAM1',
          lot: 19,
          expected: 20,
        ),
      );
      final o = w.orders.first;
      for (var i = 0; i < 15; i++) {
        w.receive(o.barcode, 'A-01');
      }
      w.receive(o.barcode, 'ES-19');
      expect(
        () => w.move(o.id, 'ES-19', 'A-01', 1),
        throwsA(isA<WarehouseError>()),
      );
    });
    test('lecturas rechazadas no alteran cantidades', () {
      final w = Warehouse.demo(received: false);
      final o = w.orders.first;
      expect(
        () => w.receive(o.barcode, 'NO-EXISTE'),
        throwsA(isA<WarehouseError>()),
      );
      expect(
        () => w.receive('desconocido', 'A-01'),
        throwsA(isA<WarehouseError>()),
      );
      expect(w.total('received'), 0);
      for (var i = 0; i < o.expected; i++) {
        w.receive(o.barcode, 'A-01');
      }
      expect(
        () => w.receive(o.barcode, 'A-01'),
        throwsA(isA<WarehouseError>()),
      );
      expect(o.received, o.expected);
    });
    test('cada caja de un pedido puede registrarse en otra ubicación', () {
      final w = Warehouse.demo(received: false);
      final o = w.orders[2];
      w.receive(o.barcode, 'A-01');
      w.receive(o.barcode, 'A-02');
      w.receive(o.barcode, 'ES-19');
      w.receive(o.barcode, 'REVISION');
      expect(o.locations.length, 4);
      expect(o.received, 4);
      expect(o.review, 1);
    });
    test('buscar no muta el inventario', () {
      final w = Warehouse.demo();
      final before = w.toJson().toString();
      w.resolve(w.orders.first.contact);
      w.route('CAM102');
      expect(w.toJson().toString(), before);
    });
    test('rechaza caja de otro vehículo sin verificarla', () {
      final w = Warehouse.demo();
      final o = w.orders[1];
      expect(
        () => w.verify(o.barcode, 'CAM102'),
        throwsA(isA<WarehouseError>()),
      );
      expect(o.verified, 0);
    });
    test('pedido multibulto sigue pendiente hasta su última caja', () {
      final w = Warehouse.demo();
      final o = w.orders[1];
      w.verify(o.barcode, o.vehicle);
      expect(o.pending, o.expected - 1);
      expect(o.verified, 1);
      expect(w.complete(o.vehicle), false);
    });
    test('no compensa faltantes de un pedido con excedentes de otro', () {
      final w = Warehouse.demo();
      final o = w.orders[1];
      for (var i = 0; i < o.expected; i++) {
        w.verify(o.barcode, o.vehicle);
      }
      expect(
        () => w.verify(o.barcode, o.vehicle),
        throwsA(isA<WarehouseError>()),
      );
      expect(w.complete(o.vehicle), false);
    });
    test('cuadrada únicamente cuando todos los pedidos coinciden', () {
      final w = Warehouse.demo();
      for (final o in w.route('CAM105')) {
        for (var i = 0; i < o.expected; i++) {
          w.verify(o.barcode, o.vehicle);
        }
      }
      expect(w.complete('CAM105'), true);
      expect(w.complete('CAM102'), false);
      expect(w.complete('NO-EXISTE'), false);
      w.undo('verify', vehicle: 'CAM105');
      expect(w.complete('CAM105'), false);
    });
    test('no verifica sin recibir; revision informa sin bloquear', () {
      final empty = Warehouse.demo(received: false);
      expect(
        () => empty.verify(empty.orders.first.barcode, 'CAM102'),
        throwsA(isA<WarehouseError>()),
      );
      final w = Warehouse.demo();
      final o = w.orders.first;
      expect(o.awaiting + o.review + o.verified, o.received);
      w.verify(o.barcode, o.vehicle);
      w.verify(o.barcode, o.vehicle);
      expect(o.review, 0);
      expect(o.verified, o.expected);
      expect(o.awaiting + o.review + o.verified, o.received);
    });
    test('liberar revisión conserva total y permite cuadre', () {
      final w = Warehouse.demo();
      final o = w.orders.first;
      final total = w.total('received');
      w.move(o.id, 'REVISION', 'ES-19', 1);
      expect(w.total('received'), total);
      expect(o.review, 0);
      for (var i = 0; i < o.expected; i++) {
        w.verify(o.barcode, o.vehicle);
      }
      expect(o.pending, 0);
    });
    test('verificar no inventa la zona de origen', () {
      final w = Warehouse.demo();
      final o = w.orders[1];
      final locations = Map.of(o.locations);
      w.verify(o.barcode, o.vehicle);
      expect(o.locations, locations);
      expect(o.stored, o.received - 1);
    });
    test('undo recepción protegido cuando hubo movimiento o cuadre', () {
      final w = Warehouse.demo(received: false);
      final o = w.orders.first;
      w.receive(o.barcode, 'A-01');
      w.move(o.id, 'A-01', 'A-02', 1);
      expect(() => w.undo('receive'), throwsA(isA<WarehouseError>()));
      final x = Warehouse.demo(received: false);
      final p = x.orders.first;
      x.receive(p.barcode, 'A-01');
      x.verify(p.barcode, p.vehicle);
      expect(() => x.undo('receive'), throwsA(isA<WarehouseError>()));
    });
    test('guarda y restaura distribución, cuadre y bitácora', () {
      final w = Warehouse.demo();
      w.verify(w.orders[1].barcode, 'CAM105');
      final restored = w.copy();
      expect(restored.toJson(), w.toJson());
      restored.undo('verify', vehicle: 'CAM105');
      expect(w.orders[1].verified, 1);
    });
    test('contacto ambiguo exige guía, sin seleccionar por conveniencia', () {
      final w = Warehouse.empty();
      for (final lot in [19, 22]) {
        w.orders.add(
          Order(
            guide: '$lot',
            contact: '123',
            name: 'Prueba',
            vehicle: 'CAM1',
            lot: lot,
            expected: 2,
          ),
        );
      }
      expect(() => w.resolve('123'), throwsA(isA<WarehouseError>()));
      expect(w.resolve('123F22').lot, 22);
    });
    test('reimportar lote con escaneos está bloqueado', () {
      final w = Warehouse.demo();
      final before = w.toJson().toString();
      expect(
        () => w.importLot(
          Warehouse.demo(
            received: false,
          ).orders.where((o) => o.lot == 19).toList(),
          19,
        ),
        throwsA(isA<WarehouseError>()),
      );
      expect(w.toJson().toString(), before);
    });
  });
  group('Importación Excel', () {
    Uint8List workbook(List<List<dynamic>> rows) {
      final e = Excel.createExcel();
      final sheet = e['Sheet1'];
      sheet.appendRow(
        [
          'NUMERO GUIA',
          'VEHICULO',
          'CANTIDAD',
          'IDENTIFICADOR CONTACTO',
          'NOMBRE CONTACTO',
          'CAMPAÑA',
        ].map((s) => TextCellValue(s)).toList(),
      );
      for (final row in rows) {
        sheet.appendRow(
          row
              .map<CellValue>(
                (v) => v is int ? IntCellValue(v) : TextCellValue('$v'),
              )
              .toList(),
        );
      }
      return Uint8List.fromList(e.encode()!);
    }

    test('una fila con cantidad cuatro crea un pedido y cuatro esperadas', () {
      final list = parseWorkbook(
        workbook([
          ['0012', 'CAM102', 4, '000123', 'Prueba', '16-19'],
        ]),
        19,
      );
      expect(list.length, 1);
      expect(list.single.expected, 4);
      expect(list.single.received, 0);
      expect(list.single.guide, '0012');
      expect(list.single.contact, '000123');
    });
    test(
      'rechaza lote incorrecto y cantidades inválidas sin importación parcial',
      () {
        expect(
          () => parseWorkbook(
            workbook([
              ['12', 'CAM102', 4, '123', 'Prueba', '16-22'],
            ]),
            19,
          ),
          throwsA(isA<WarehouseError>()),
        );
        expect(
          () => parseWorkbook(
            workbook([
              ['12', 'CAM102', 0, '123', 'Prueba', '16-19'],
            ]),
            19,
          ),
          throwsA(isA<WarehouseError>()),
        );
      },
    );
    test('rechaza guía duplicada y vehículo vacío', () {
      final row = ['12', 'CAM102', 4, '123', 'Prueba', '16-19'];
      expect(
        () => parseWorkbook(workbook([row, row]), 19),
        throwsA(isA<WarehouseError>()),
      );
      expect(
        () => parseWorkbook(
          workbook([
            ['12', '', 4, '123', 'Prueba', '16-19'],
          ]),
          19,
        ),
        throwsA(isA<WarehouseError>()),
      );
    });
  });
}
