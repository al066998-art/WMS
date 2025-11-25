import 'package:flutter/material.dart';
import '../models/app_model.dart';

class AdminScreen extends StatefulWidget {
  final AppModel appModel;
  final VoidCallback onUpdated;

  const AdminScreen({super.key, required this.appModel, required this.onUpdated});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<LoteConfig> tempLotes = [];

  @override
  void initState() {
    super.initState();
     
    for (var lote in widget.appModel.lotesConfig) {
      tempLotes.add(LoteConfig(lote.nombre, lote.cantidad));
    }
  }

  @override
  Widget build(BuildContext context) {
     
    return Scaffold(
      appBar: AppBar(title: const Text("Configurar Lotes")),
       
      body: Column(
        children: [
           
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tempLotes.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                         
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            initialValue: tempLotes[index].nombre,
                            decoration: const InputDecoration(
                              labelText: "Nombre Lote",
                              border: InputBorder.none,  
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onChanged: (val) => tempLotes[index].nombre = val,
                          ),
                        ), 
                        Container(width: 1, height: 30, color: Colors.grey[300]),
                        const SizedBox(width: 10), 
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            initialValue: tempLotes[index].cantidad.toString(),
                            decoration: const InputDecoration(
                              labelText: "Cant.",
                              border: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (val) => tempLotes[index].cantidad = int.tryParse(val) ?? 0,
                          ),
                        ), 
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () {
                            setState(() {
                              tempLotes.removeAt(index);
                            });
                          },
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
 
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))
              ],
            ),
            child: Row(
              children: [
 
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.teal),
                      foregroundColor: Colors.teal,
                    ),
                    onPressed: () {
                      setState(() {
                        tempLotes.add(LoteConfig("Nuevo", 10));
                      });
                    },
                    icon: const Icon(Icons.add),
                    label: const Text("Nuevo Lote"),
                  ),
                ),
                const SizedBox(width: 12),
 
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () { 
                      widget.appModel.updateConfig(tempLotes);
                      widget.onUpdated();
                       
                      FocusScope.of(context).unfocus(); 
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("¡Inventario Actualizado!"),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.teal,
                        )
                      );
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Actualizar"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}