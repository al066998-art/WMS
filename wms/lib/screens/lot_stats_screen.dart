import 'package:flutter/material.dart';
import '../models/app_model.dart';
import '../models/box_model.dart';

import '../widgets/inventory_chart.dart'; 

class LotStatsScreen extends StatelessWidget {
  final AppModel appModel;

  const LotStatsScreen({super.key, required this.appModel});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text("Desglose por Lotes")),
      body: appModel.lotesConfig.isEmpty
          ? const Center(child: Text("No hay lotes configurados"))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8, 
              ),
              itemCount: appModel.lotesConfig.length,
              itemBuilder: (context, index) {
                final config = appModel.lotesConfig[index];
                
                 
                final loteBoxes = appModel.boxes.where((b) => b.lote == config.nombre).toList();
                final available = loteBoxes.where((b) => b.status == BoxStatus.Disponible).length;
                final route = loteBoxes.where((b) => b.status == BoxStatus.Salida).length;
                final maintenance = loteBoxes.where((b) => b.status == BoxStatus.Mantenimiento).length;
                final damaged = loteBoxes.where((b) => b.status == BoxStatus.Danada).length;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Lote ${config.nombre}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 15),
                        
                         
                        InventoryChart(
                          available: available,
                          route: route,
                          maintenance: maintenance,
                          damaged: damaged,
                          size: 110,  
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}