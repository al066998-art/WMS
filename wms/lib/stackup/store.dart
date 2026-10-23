import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'domain.dart';

enum AppRole { worker, admin }

class WarehouseStore extends ChangeNotifier {
  final Database db;
  Warehouse data;
  AppRole? role;
  String? _pinHash;
  String _salt = '';
  bool busy = false;
  WarehouseStore._(this.db, this.data);
  @visibleForTesting
  factory WarehouseStore.forTest(Database db, Warehouse data) =>
      WarehouseStore._(db, data);
  bool get configured => _pinHash != null;
  bool get admin => role == AppRole.admin;
  static Future<WarehouseStore> open() async {
    final root = await getDatabasesPath();
    final db = await openDatabase(
      '$root/stackup_trial_v3.db',
      version: 1,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
        await db.execute(
          'CREATE TABLE archives (id INTEGER PRIMARY KEY AUTOINCREMENT, created TEXT, data TEXT)',
        );
      },
    );
    final rows = await db.query('settings');
    final values = {
      for (final r in rows) r['key'] as String: r['value'] as String,
    };
    final store = WarehouseStore._(
      db,
      values['warehouse'] == null
          ? Warehouse.demo()
          : Warehouse.fromJson(jsonDecode(values['warehouse']!)),
    );
    store._pinHash = values['pin'];
    store._salt = values['salt'] ?? '';
    return store;
  }

  String _hash(String pin) =>
      sha256.convert(utf8.encode('$_salt:$pin')).toString();
  Future<void> setup(String pin) async {
    if (configured || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw WarehouseError('Elige un PIN de 6 dígitos.');
    }
    _salt = List.generate(24, (_) => Random.secure().nextInt(256)).join('-');
    final hash = _hash(pin);
    await db.transaction((txn) async {
      for (final e in {
        'pin': hash,
        'salt': _salt,
        'warehouse': jsonEncode(data.toJson()),
      }.entries) {
        await txn.insert('settings', {
          'key': e.key,
          'value': e.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
    _pinHash = hash;
    role = AppRole.admin;
    notifyListeners();
  }

  void loginWorker() {
    role = AppRole.worker;
    notifyListeners();
  }

  void loginAdmin(String pin) {
    if (_hash(pin) != _pinHash) throw WarehouseError('PIN incorrecto.');
    role = AppRole.admin;
    notifyListeners();
  }

  void logout() {
    role = null;
    notifyListeners();
  }

  Future<void> change(
    void Function(Warehouse) action, {
    bool adminOnly = false,
  }) async {
    if (role == null || (adminOnly && !admin)) {
      throw WarehouseError('Acceso no autorizado.');
    }
    if (busy) throw WarehouseError('Espera a que termine la lectura anterior.');
    busy = true;
    try {
      final next = data.copy();
      action(next);
      await db.insert('settings', {
        'key': 'warehouse',
        'value': jsonEncode(next.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      data = next;
      notifyListeners();
    } finally {
      busy = false;
    }
  }

  Future<void> reset(Warehouse next) async {
    if (!admin || busy) {
      throw WarehouseError('Se requiere administrador y una captura inactiva.');
    }
    busy = true;
    try {
      await db.transaction((txn) async {
        await txn.insert('archives', {
          'created': DateTime.now().toIso8601String(),
          'data': jsonEncode(data.toJson()),
        });
        await txn.insert('settings', {
          'key': 'warehouse',
          'value': jsonEncode(next.toJson()),
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      });
      data = next;
      notifyListeners();
    } finally {
      busy = false;
    }
  }
}
