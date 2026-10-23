import 'package:flutter/material.dart';
import 'stackup/app.dart';
import 'stackup/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final store = await WarehouseStore.open();
    runApp(StackUpApp(store: store));
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No se pudo abrir el almacenamiento local. No se borraron tus datos.\n\n$e',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
