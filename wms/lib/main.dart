import 'package:flutter/material.dart';
import './models/app_model.dart';
import './screens/home_screen.dart';
import './screens/consultas_screen.dart';
import './screens/admin_screen.dart';

void main() {
  runApp(const BodegaProApp());
}

class BodegaProApp extends StatefulWidget {
  const BodegaProApp({super.key});

  @override
  State<BodegaProApp> createState() => _BodegaProAppState();
}

class _BodegaProAppState extends State<BodegaProApp> {
  final AppModel appModel = AppModel();
  int _currentIndex = 0;


  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bodega Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: ListenableBuilder(
        listenable: appModel,
        builder: (context, child) {
          final pages = [
            HomeScreen(appModel: appModel, onTabChange: changeTab),
            ConsultasScreen(appModel: appModel),
            AdminScreen(appModel: appModel, onUpdated: () {}),
          ];

          return Scaffold(
            body: SafeArea(
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: changeTab,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.dashboard), label: 'inicio'),
                NavigationDestination(icon: Icon(Icons.inventory), label: 'Consultas'),
                NavigationDestination(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
              ],
            ),
          );
        },
      ),
    );
  }
}