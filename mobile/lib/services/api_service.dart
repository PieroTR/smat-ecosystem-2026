import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estacion.dart';
import 'auth_service.dart';

class ApiService {
  // Configurado para Chrome
  final String baseUrl = "http://localhost:8000";

  Future<List<Estacion>> fetchEstaciones() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/estaciones/"),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        return jsonResponse.map((data) => Estacion.fromJson(data)).toList();
      } else {
        print("Error del servidor: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error de conexión: $e");
      return [];
    }
  }

  Future<bool> crearEstacion(String nombre, String ubicacion) async {
    final token = await AuthService().getToken();
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/estaciones/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nombre': nombre, 'ubicacion': ubicacion}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // === NUEVOS MÉTODOS LABORATORIO 6.2 ===

  // 1. Eliminar una estación [cite: 18, 19]
  Future<bool> eliminarEstacion(int id) async {
    final token = await AuthService().getToken(); // Siempre enviando el token de seguridad [cite: 16, 21]
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/estaciones/$id'), // Ruta dinámica con el ID [cite: 24]
        headers: {
          'Authorization': 'Bearer $token', // Encabezado de autorización [cite: 25]
        },
      );
      return response.statusCode == 200; // Retorna true si la eliminación fue exitosa [cite: 26]
    } catch (e) {
      print("Error al eliminar: $e");
      return false;
    }
  }

  // 2. Actualizar una estación existente [cite: 27, 28]
  Future<bool> editarEstacion(int id, String nombre, String ubicacion) async {
    final token = await AuthService().getToken();
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/estaciones/$id'), // Usamos el método PUT para actualizar [cite: 38]
        headers: {
          'Content-Type': 'application/json', // Importante para enviar el JSON [cite: 41]
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nombre': nombre, 
          'ubicacion': ubicacion
        }), // Cuerpo con los nuevos datos [cite: 43]
      );
      return response.statusCode == 200; // Confirmación de actualización [cite: 44]
    } catch (e) {
      print("Error al editar: $e");
      return false;
    }
  }
}