class Estacion {
  final int id;
  final String nombre;
  final String ubicacion;
  final double ultimoValor; // Añadimos este campo para el reto

  Estacion({
    required this.id, 
    required this.nombre, 
    required this.ubicacion, 
    required this.ultimoValor,
  });

  factory Estacion.fromJson(Map<String, dynamic> json) {
    return Estacion(
      id: json['id'],
      nombre: json['nombre'],
      ubicacion: json['ubicacion'],
      ultimoValor: (json['ultimoValor'] ?? 0.0).toDouble(), 
    );
  }
}