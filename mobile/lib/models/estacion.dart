class Estacion {
  final int id;
  final String nombre;
  final String ubicacion;
  final double ultimoValor; // Añadimos este campo para el reto [cite: 123]

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
      // Usamos .toDouble() para evitar errores si el JSON trae un entero
      ultimoValor: (json['ultimo_valor'] ?? 0.0).toDouble(), 
    );
  }
}