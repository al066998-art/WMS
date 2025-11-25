enum BoxStatus { Disponible, Salida, Danada, Mantenimiento }

class BoxModel {
  final String id;
  final String lote;
  BoxStatus status; 

  BoxModel({
    required this.id,
    required this.lote,
    this.status = BoxStatus.Disponible,
  });

 
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lote': lote,
      'status': status.index,  
    };
  }

 
  factory BoxModel.fromJson(Map<String, dynamic> json) {
    return BoxModel(
      id: json['id'],
      lote: json['lote'],
      status: BoxStatus.values[json['status']],  
    );
  }
}