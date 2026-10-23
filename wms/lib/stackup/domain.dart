import 'dart:convert';

class WarehouseError implements Exception {
  final String message;
  WarehouseError(this.message);
  @override
  String toString() => message;
}

class Zone {
  final String code;
  final String kind;
  Zone(this.code, {this.kind = 'normal'});
  Map<String, dynamic> toJson() => {'code': code, 'kind': kind};
  factory Zone.fromJson(Map<String, dynamic> j) =>
      Zone(j['code'], kind: j['kind']);
}

class Order {
  final String guide, contact, name, vehicle;
  final int lot, expected;
  final Map<String, int> locations;
  int verified;
  String get id => '$lot:$guide';
  String get barcode => '${contact}F$guide';
  int get received => locations.values.fold(0, (a, b) => a + b);
  int get pending => expected - verified;
  int get stored => received - verified;
  // Conserva la señal de revisión hasta que las cantidades verificadas
  // requieran reducirla. No deduce la ubicación física de una caja idéntica.
  int get review => (locations['REVISION'] ?? 0).clamp(0, stored);
  int get awaiting => stored - review;
  Order({
    required this.guide,
    required this.contact,
    required this.name,
    required this.vehicle,
    required this.lot,
    required this.expected,
    Map<String, int>? locations,
    this.verified = 0,
  }) : locations = locations ?? {};
  Map<String, dynamic> toJson() => {
    'guide': guide,
    'contact': contact,
    'name': name,
    'vehicle': vehicle,
    'lot': lot,
    'expected': expected,
    'locations': locations,
    'verified': verified,
  };
  factory Order.fromJson(Map<String, dynamic> j) => Order(
    guide: j['guide'],
    contact: j['contact'],
    name: j['name'],
    vehicle: j['vehicle'],
    lot: j['lot'],
    expected: j['expected'],
    locations: Map<String, int>.from(j['locations']),
    verified: j['verified'],
  );
}

class Warehouse {
  String reception;
  List<Order> orders;
  List<Zone> zones;
  List<Map<String, dynamic>> events;
  Warehouse({
    required this.reception,
    required this.orders,
    required this.zones,
    List<Map<String, dynamic>>? events,
  }) : events = events ?? [];
  factory Warehouse.empty() => Warehouse(
    reception: 'Campaña actual',
    orders: [],
    zones: [
      for (var i = 1; i <= 8; i++) Zone('A-${i.toString().padLeft(2, '0')}'),
      Zone('ES-19', kind: 'special'),
      Zone('ES-22', kind: 'special'),
      Zone('REVISION', kind: 'review'),
    ],
  );
  factory Warehouse.demo({bool received = true}) {
    final w = Warehouse.empty();
    w.zones = [
      for (var i = 1; i <= 24; i++) Zone('A-${i.toString().padLeft(2, '0')}'),
      Zone('ES-19', kind: 'special'),
      Zone('ES-22', kind: 'special'),
      Zone('REVISION', kind: 'review'),
    ];
    w.reception = 'Demostración · datos ficticios';
    const names = [
      'María López',
      'Ana Pérez',
      'Lucía Méndez',
      'Elena Cruz',
      'Rosa García',
      'Sofía Díaz',
      'Laura Vega',
      'Marta Ruiz',
      'Julia Soto',
      'Sara León',
      'Clara Mora',
      'Irene Gil',
    ];
    var zoneNumber = 1;
    var zoneBoxes = 0;
    for (var i = 0; i < 100; i++) {
      final lot = i < 60 ? 19 : 22;
      // El siguiente lote empieza en una zona nueva, sin asignar permanentemente
      // zonas ni vehículos a un lote.
      if (i == 60 && zoneBoxes > 0) {
        zoneNumber++;
        zoneBoxes = 0;
      }
      final n = 2 + i % 4;
      final locations = <String, int>{};
      if (received) {
        for (var box = 0; box < n; box++) {
          String zone;
          if (i == 0 && box == 0) {
            zone = 'REVISION';
          } else if (i % 10 == 9 && box == n - 1) {
            zone = 'ES-$lot';
          } else {
            if (zoneBoxes == 15) {
              zoneNumber++;
              zoneBoxes = 0;
            }
            zone = 'A-${zoneNumber.toString().padLeft(2, '0')}';
            zoneBoxes++;
          }
          locations[zone] = (locations[zone] ?? 0) + 1;
        }
      }
      w.orders.add(
        Order(
          guide: '${34164335 + i}',
          contact: '${10668481 + i}',
          name: '${names[i % names.length]} ${i ~/ names.length + 1}',
          vehicle: lot == 19
              ? ['CAM102', 'CAM105', 'CAM108', 'CAM111', 'CAM114'][i % 5]
              : ['CAM201', 'CAM204', 'CAM207', 'CAM210', 'CAM213'][i % 5],
          lot: lot,
          expected: n,
          locations: locations,
        ),
      );
    }
    return w;
  }
  List<String> get vehicles =>
      orders.map((o) => o.vehicle).toSet().toList()..sort();
  List<Order> route(String vehicle) =>
      orders.where((o) => o.vehicle == vehicle).toList();
  int zoneCount(String code) =>
      orders.fold(0, (n, o) => n + (o.locations[code] ?? 0));
  int? zoneCapacity(String code) =>
      zones.singleWhere((z) => z.code == code).kind == 'normal' ? 15 : null;
  bool zoneFull(String code) =>
      zoneCapacity(code) != null && zoneCount(code) >= zoneCapacity(code)!;
  bool complete(String vehicle) =>
      route(vehicle).isNotEmpty &&
      route(vehicle).every((o) => o.verified == o.expected);
  int total(String field, {int? lot}) => orders
      .where((o) => lot == null || o.lot == lot)
      .fold(
        0,
        (n, o) =>
            n +
            switch (field) {
              'expected' => o.expected,
              'received' => o.received,
              'verified' => o.verified,
              'review' => o.review,
              'special' =>
                o.locations.entries
                    .where(
                      (e) => zones.any(
                        (z) => z.code == e.key && z.kind == 'special',
                      ),
                    )
                    .fold(0, (a, e) => a + e.value),
              _ => o.stored,
            },
      );

  Order resolve(String raw) {
    final code = raw.trim().toUpperCase();
    if (code.isEmpty) throw WarehouseError('Escanea o escribe un código.');
    // Formato provisional confirmado con códigos de demostración.
    // El formato real de la etiqueta debe validarse antes del uso operativo.
    final split = RegExp(r'^(\d+)F(\d+)$').firstMatch(code);
    final matches = orders
        .where(
          (o) => split != null
              ? o.contact == split.group(1) && o.guide == split.group(2)
              : o.contact == code || o.guide == code,
        )
        .toList();
    if (matches.isEmpty) {
      throw WarehouseError('Código no encontrado en esta recepción.');
    }
    if (matches.length != 1) {
      throw WarehouseError(
        'Código ambiguo: usa consejeraFguía para distinguir el pedido.',
      );
    }
    return matches.single;
  }

  void log(String type, Order o, {String? zone}) {
    events.add({
      'type': type,
      'order': o.id,
      'zone': zone,
      'at': DateTime.now().toIso8601String(),
    });
  }

  Order receive(String raw, String zone) {
    if (!zones.any((z) => z.code == zone)) {
      throw WarehouseError('Selecciona una zona válida.');
    }
    if (zoneFull(zone)) {
      throw WarehouseError('Zona $zone completa (15/15). Escanea otra zona.');
    }
    final o = resolve(raw);
    if (o.received >= o.expected) {
      throw WarehouseError(
        'Cantidad recibida completa (${o.expected}). No se agregó otra caja.',
      );
    }
    o.locations[zone] = (o.locations[zone] ?? 0) + 1;
    log('receive', o, zone: zone);
    return o;
  }

  Order verify(String raw, String vehicle) {
    final o = resolve(raw);
    if (o.vehicle != vehicle) {
      throw WarehouseError(
        'Caja de otro vehículo: corresponde a ${o.vehicle}. No se agregó.',
      );
    }
    if (o.verified >= o.expected) {
      throw WarehouseError(
        'Pedido completo: ${o.expected} cajas ya verificadas.',
      );
    }
    if (o.verified >= o.received) {
      throw WarehouseError(
        'No hay más cajas recibidas de este pedido. Revisa la recepción.',
      );
    }
    o.verified++;
    log('verify', o);
    return o;
  }

  void undo(String eventType, {String? vehicle}) {
    final index = events.lastIndexWhere(
      (e) =>
          e['type'] == eventType &&
          e['undone'] != true &&
          orders.any(
            (o) =>
                o.id == e['order'] && (vehicle == null || o.vehicle == vehicle),
          ),
    );
    if (index < 0) throw WarehouseError('No hay lecturas para deshacer.');
    final event = events[index];
    final o = orders.singleWhere((o) => o.id == event['order']);
    if (eventType == 'verify') {
      if (o.verified == 0) {
        throw WarehouseError('La lectura ya no se puede deshacer.');
      }
      o.verified--;
    } else {
      final zone = event['zone'] as String;
      if (o.verified > 0 ||
          (o.locations[zone] ?? 0) == 0 ||
          events
              .skip(index + 1)
              .any((e) => e['order'] == o.id && e['type'] == 'move')) {
        throw WarehouseError(
          'El pedido tiene movimientos posteriores. Usa una corrección de ubicación.',
        );
      }
      o.locations[zone] = o.locations[zone]! - 1;
      o.locations.removeWhere((k, v) => v == 0);
    }
    event['undone'] = true;
  }

  void move(String id, String from, String to, int count) {
    final o = orders.singleWhere((o) => o.id == id);
    if (o.verified > 0) {
      throw WarehouseError(
        'Deshaz el cuadre del pedido antes de corregir sus ubicaciones.',
      );
    }
    if (from == to ||
        !zones.any((z) => z.code == to) ||
        count < 1 ||
        count > (o.locations[from] ?? 0)) {
      throw WarehouseError(
        'Selecciona ubicaciones distintas y una cantidad válida.',
      );
    }
    final capacity = zoneCapacity(to);
    if (capacity != null && zoneCount(to) + count > capacity) {
      throw WarehouseError('La corrección excede las 15 cajas de la zona $to.');
    }
    o.locations[from] = o.locations[from]! - count;
    o.locations[to] = (o.locations[to] ?? 0) + count;
    o.locations.removeWhere((k, v) => v == 0);
    log('move', o, zone: '$from → $to ($count)');
  }

  void importLot(List<Order> incoming, int lot) {
    if (orders.any((o) => o.lot == lot && (o.received > 0 || o.verified > 0))) {
      throw WarehouseError(
        'Este lote ya tiene escaneos. Abre una nueva recepción para reemplazarlo.',
      );
    }
    if (incoming.isEmpty || incoming.any((o) => o.lot != lot)) {
      throw WarehouseError('Archivo vacío o lote incorrecto.');
    }
    if (incoming.map((o) => o.id).toSet().length != incoming.length) {
      throw WarehouseError('Hay guías duplicadas en el archivo.');
    }
    final vehicleLots = <String, int>{};
    for (final o in [...orders.where((o) => o.lot != lot), ...incoming]) {
      final vehicle = o.vehicle.trim().toUpperCase();
      final assignedLot = vehicleLots[vehicle];
      if (assignedLot != null && assignedLot != o.lot) {
        throw WarehouseError(
          'El vehículo $vehicle ya tiene pedidos del lote $assignedLot. '
          'Una ruta solo puede tener un lote por campaña. '
          'Corrige el vehículo en el Excel. No se importó ningún dato.',
        );
      }
      vehicleLots[vehicle] = o.lot;
    }
    orders.removeWhere((o) => o.lot == lot);
    orders.addAll(incoming);
  }

  Map<String, dynamic> toJson() => {
    'reception': reception,
    'orders': orders.map((o) => o.toJson()).toList(),
    'zones': zones.map((z) => z.toJson()).toList(),
    'events': events,
  };
  factory Warehouse.fromJson(Map<String, dynamic> j) => Warehouse(
    reception: j['reception'],
    orders: (j['orders'] as List)
        .map((o) => Order.fromJson(Map<String, dynamic>.from(o)))
        .toList(),
    zones: (j['zones'] as List)
        .map((o) => Zone.fromJson(Map<String, dynamic>.from(o)))
        .toList(),
    events: (j['events'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList(),
  );
  Warehouse copy() => Warehouse.fromJson(jsonDecode(jsonEncode(toJson())));
}
