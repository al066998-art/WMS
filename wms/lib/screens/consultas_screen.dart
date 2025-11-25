import 'package:flutter/material.dart';
import '../models/app_model.dart';
import '../models/box_model.dart';

class ConsultasScreen extends StatefulWidget {
  final AppModel appModel;
  const ConsultasScreen({super.key, required this.appModel});

  @override
  State<ConsultasScreen> createState() => _ConsultasScreenState();
}

class _ConsultasScreenState extends State<ConsultasScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final items = widget.appModel.boxes.where((b) {
      if (query.isEmpty) return true;
      return b.id.toLowerCase().contains(query.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(title: const Text('Consultas • Inventario')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Buscador
            TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                hintText: 'Buscar caja (ej. 19-001)',
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              ),
              onChanged: (v) => setState(() => query = v.trim()),
            ),
            const SizedBox(height: 12),
            
            // Lista
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text('No se encontraron cajas', style: TextStyle(color: Colors.grey[600])))
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final BoxModel b = items[index];
                        
                         
                        Color statusColor = Colors.teal;  
                        IconData statusIcon = Icons.check_circle;
                        
                        if (b.status == BoxStatus.Salida) {
                          statusColor = Colors.grey;  
                          statusIcon = Icons.local_shipping;
                        } else if (b.status == BoxStatus.Danada) {
                          statusColor = Colors.red;  
                          statusIcon = Icons.dangerous;
                        } else if (b.status == BoxStatus.Mantenimiento) {
                          statusColor = Colors.amber.shade700; 
                          statusIcon = Icons.build_circle;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200)
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: statusColor.withOpacity(0.1),
                              child: Icon(statusIcon, color: statusColor, size: 22),
                            ),
                            title: Text(b.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Lote ${b.lote} • ${b.status.name}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                            
                            
                            trailing: Icon(Icons.more_vert, size: 22, color: Colors.teal.shade300),
                            
                            onTap: () => _mostrarMenuDeEstado(context, b),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMenuDeEstado(BuildContext context, BoxModel box) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              Text("Gestionar Caja: ${box.id}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
               
              _buildOption(
                icon: Icons.check_circle_outline, color: Colors.teal, text: "Disponible", 
                isSelected: box.status == BoxStatus.Disponible,
                onTap: () { widget.appModel.updateBoxStatus(box.id, BoxStatus.Disponible); Navigator.pop(context); }
              ),
               
              _buildOption(
                icon: Icons.local_shipping_outlined, color: Colors.grey, text: "En Ruta / Fuera", 
                isSelected: box.status == BoxStatus.Salida,
                onTap: () { widget.appModel.updateBoxStatus(box.id, BoxStatus.Salida); Navigator.pop(context); }
              ),
               
              _buildOption(
                icon: Icons.build_outlined, color: Colors.amber.shade700, text: "En Mantenimiento", 
                isSelected: box.status == BoxStatus.Mantenimiento,
                onTap: () { widget.appModel.updateBoxStatus(box.id, BoxStatus.Mantenimiento); Navigator.pop(context); }
              ),
               
              _buildOption(
                icon: Icons.dangerous_outlined, color: Colors.red, text: "Dañada / Rota", 
                isSelected: box.status == BoxStatus.Danada,
                onTap: () { widget.appModel.updateBoxStatus(box.id, BoxStatus.Danada); Navigator.pop(context); }
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption({required IconData icon, required Color color, required String text, required VoidCallback onTap, bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: color.withOpacity(0.5)) : null
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(text, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.black87)),
        trailing: isSelected ? Icon(Icons.check, color: color) : null,
        onTap: onTap,
      ),
    );
  }
}