import 'package:flutter/material.dart';
import 'dart:convert'; // Necesario para JSON
import 'package:shared_preferences/shared_preferences.dart'; // Necesario para guardar
import 'box_model.dart';

class LoteConfig {
  String nombre;
  int cantidad;
  LoteConfig(this.nombre, this.cantidad);
 
  Map<String, dynamic> toJson() => {'nombre': nombre, 'cantidad': cantidad};
 
  factory LoteConfig.fromJson(Map<String, dynamic> json) {
    return LoteConfig(json['nombre'], json['cantidad']);
  }
}

class AppModel extends ChangeNotifier {
  List<LoteConfig> lotesConfig = [];
  List<BoxModel> boxes = [];
 
  AppModel() {
    _loadData();
  }
 
  int get totalBoxes => boxes.length;
  int get sentBoxes => boxes.where((b) => b.status == BoxStatus.Salida).length;
  int get maintenanceBoxes => boxes.where((b) => b.status == BoxStatus.Mantenimiento).length;
  int get damagedBoxes => boxes.where((b) => b.status == BoxStatus.Danada).length;
  int get availableBoxes => boxes.where((b) => b.status == BoxStatus.Disponible).length;
  double get availabilityPercentage {
    if (totalBoxes == 0) return 0.0;
    return (availableBoxes / totalBoxes) * 100.0;
  }

 

  void updateConfig(List<LoteConfig> nuevosLotes) {
    lotesConfig = nuevosLotes;
     
    boxes.clear();
    for (var config in lotesConfig) {
      for (int i = 1; i <= config.cantidad; i++) {
        boxes.add(BoxModel(
          id: '${config.nombre}-${i.toString().padLeft(3, '0')}', 
          lote: config.nombre, 
          status: BoxStatus.Disponible
        ));
      }
    }
    notifyListeners();
    _saveData(); 
  }

  void updateBoxStatus(String id, BoxStatus newStatus) {
    final index = boxes.indexWhere((b) => b.id == id);
    if (index != -1) {
      boxes[index].status = newStatus;
      notifyListeners();
      _saveData();  
    }
  }
 
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
 
    final lotesJson = jsonEncode(lotesConfig.map((l) => l.toJson()).toList());
    
   
    final boxesJson = jsonEncode(boxes.map((b) => b.toJson()).toList());

    await prefs.setString('lotes_data', lotesJson);
    await prefs.setString('boxes_data', boxesJson);
  }

 
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.containsKey('lotes_data') && prefs.containsKey('boxes_data')) {
 
      final lotesString = prefs.getString('lotes_data')!;
      final lotesList = jsonDecode(lotesString) as List;
      lotesConfig = lotesList.map((json) => LoteConfig.fromJson(json)).toList();
 
      final boxesString = prefs.getString('boxes_data')!;
      final boxesList = jsonDecode(boxesString) as List;
      boxes = boxesList.map((json) => BoxModel.fromJson(json)).toList();
      
      notifyListeners();
    } else {
 
      _loadInitialDemo();
    }
  }

  void _loadInitialDemo() {
    lotesConfig = [
      LoteConfig("19", 20),
      LoteConfig("20", 30),
    ];
 
    boxes.clear();
    for (var config in lotesConfig) {
      for (int i = 1; i <= config.cantidad; i++) {
        boxes.add(BoxModel(
          id: '${config.nombre}-${i.toString().padLeft(3, '0')}', 
          lote: config.nombre, 
          status: BoxStatus.Disponible
        ));
      }
    }
    notifyListeners();
    _saveData();  
  }
}