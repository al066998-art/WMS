import 'package:flutter/material.dart';
import '../models/app_model.dart';
import '../models/box_model.dart';
import '../widgets/inventory_chart.dart'; 
import 'lot_stats_screen.dart';

class HomeScreen extends StatelessWidget {
  final AppModel appModel;
  final Function(int) onTabChange;

  const HomeScreen({
    super.key, 
    required this.appModel,
    required this.onTabChange, 
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Bodega • Dashboard'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Colors.white, 
              child: Icon(Icons.person, color: Colors.teal)
            ),
          )
        ],
      ),
       
      body: Column(
        children: [
           
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TARJETA DEL GRÁFICO
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    elevation: 2,
                    child: InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LotStatsScreen(appModel: appModel))),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Estado del Inventario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Icon(Icons.pie_chart, color: Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 25),
                            
                            InventoryChart(
                              available: appModel.availableBoxes,
                              route: appModel.sentBoxes,
                              maintenance: appModel.maintenanceBoxes,
                              damaged: appModel.damagedBoxes,
                              size: 170,
                            ),
                            
                            const SizedBox(height: 30),
                            
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _legendItem("Disponibles", appModel.availableBoxes, Colors.teal)),
                                    Expanded(child: _legendItem("En Ruta", appModel.sentBoxes, Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Row(
                                  children: [
                                    Expanded(child: _legendItem("Mantenimiento", appModel.maintenanceBoxes, Colors.amber.shade700)),
                                    Expanded(child: _legendItem("Dañadas", appModel.damagedBoxes, Colors.red)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  
                   
                  Row(
                    children: [
                      Expanded(child: _actionButton(icon: Icons.search, label: "Buscar Caja", onTap: () => onTabChange(1))),
                      const SizedBox(width: 12),
                      Expanded(child: _actionButton(icon: Icons.settings_outlined, label: "Configurar", onTap: () => onTabChange(2))),
                    ],
                  ),

                  const SizedBox(height: 25),
                  const Text('Últimos movimientos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 10),

                   
                  appModel.boxes.isEmpty 
                  ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No hay cajas registradas")))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: appModel.boxes.length > 5 ? 5 : appModel.boxes.length,
                      itemBuilder: (context, i) {
                        final box = appModel.boxes[appModel.boxes.length - 1 - i];
                        
                        IconData icon = Icons.check_circle_outline;
                        Color color = Colors.teal;
                        
                        if (box.status == BoxStatus.Salida) {
                          icon = Icons.local_shipping_outlined;
                          color = Colors.grey;
                        } else if (box.status == BoxStatus.Mantenimiento) {
                          icon = Icons.build_circle_outlined;
                          color = Colors.amber.shade700;
                        } else if (box.status == BoxStatus.Danada) {
                          icon = Icons.dangerous_outlined;
                          color = Colors.red;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(icon, color: color),
                            ),
                            title: Text(box.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text("Lote ${box.lote} • ${box.status.name}"),
                            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                            onTap: () {
                              onTabChange(1); 
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ver detalles de ${box.id}..."), duration: const Duration(milliseconds: 500)));
                            },
                          ),
                        );
                      },
                    )
                ],
              ),
            ),
          ),

          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            color: Colors.grey[50],  
            child: const Center(
              child: Text(
                 
                "Desarrollado por Sergio Foster y Oziel Canul",
                style: TextStyle(
                  fontSize: 11,  
                  color: Colors.grey, 
                  fontWeight: FontWeight.w500
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        )
      ],
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
      ),
      icon: Icon(icon, color: Colors.teal),
      label: Text(label),
      onPressed: onTap,
    );
  }
}