import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'domain.dart';

String normalizeHeader(String value) {
  var s = value.trim().toUpperCase();
  const accents = {'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ñ': 'N'};
  accents.forEach((k, v) {
    s = s.replaceAll(k, v);
  });
  return s.replaceAll(RegExp(r'[^A-Z0-9]'), '');
}

List<Order> parseWorkbook(Uint8List bytes, int expectedLot) {
  final book = Excel.decodeBytes(bytes);
  final output = <Order>[];
  final errors = <String>[];
  var found = false;
  for (final sheet in book.tables.values) {
    final rows = sheet.rows;
    if (rows.every((r) => r.every((v) => v?.value == null))) continue;
    final headerIndex = rows.indexWhere(
      (r) => r.any(
        (v) => normalizeHeader(v?.value?.toString() ?? '') == 'NUMEROGUIA',
      ),
    );
    if (headerIndex < 0) {
      errors.add('${sheet.sheetName}: no se encontró NUMERO GUIA.');
      continue;
    }
    found = true;
    final headers = rows[headerIndex]
        .map((v) => normalizeHeader(v?.value?.toString() ?? ''))
        .toList();
    const requiredHeaders = [
      'NUMEROGUIA',
      'VEHICULO',
      'CANTIDAD',
      'IDENTIFICADORCONTACTO',
      'CAMPANA',
    ];
    final missing = requiredHeaders.where((h) => !headers.contains(h)).toList();
    if (missing.isNotEmpty) {
      errors.add('${sheet.sheetName}: faltan ${missing.join(', ')}.');
      continue;
    }
    for (var i = headerIndex + 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every(
        (v) => v?.value == null || v!.value.toString().trim().isEmpty,
      )) {
        continue;
      }
      String cell(String key) {
        final n = headers.indexOf(key);
        if (n < 0 || n >= row.length) return '';
        final value = row[n]?.value;
        if (value is DoubleCellValue &&
            value.value == value.value.roundToDouble()) {
          return value.value.toInt().toString();
        }
        return value?.toString().trim() ?? '';
      }

      final guide = cell('NUMEROGUIA');
      final contact = cell('IDENTIFICADORCONTACTO');
      final vehicle = cell('VEHICULO').toUpperCase();
      final quantity = int.tryParse(cell('CANTIDAD'));
      final campaign = cell('CAMPANA');
      final match = RegExp(r'^16\s*-\s*(19|22)$').firstMatch(campaign);
      final lot = match == null ? null : int.parse(match.group(1)!);
      if (guide.isEmpty ||
          contact.isEmpty ||
          vehicle.isEmpty ||
          quantity == null ||
          quantity <= 0 ||
          lot != expectedLot) {
        errors.add(
          '${sheet.sheetName}, fila ${i + 1}: revisa guía, consejera, vehículo, cantidad positiva y lote 16-$expectedLot.',
        );
        continue;
      }
      output.add(
        Order(
          guide: guide,
          contact: contact,
          name: cell('NOMBRECONTACTO'),
          vehicle: vehicle,
          lot: lot!,
          expected: quantity,
        ),
      );
    }
  }
  if (!found) {
    throw WarehouseError('No se encontró una hoja con las columnas esperadas.');
  }
  if (errors.isNotEmpty) {
    throw WarehouseError(
      '${errors.take(6).join('\n')}\nNo se importó ningún dato.',
    );
  }
  if (output.isEmpty) throw WarehouseError('El archivo no contiene pedidos.');
  if (output.map((o) => o.id).toSet().length != output.length) {
    throw WarehouseError('Hay guías duplicadas. No se importó el archivo.');
  }
  return output;
}
