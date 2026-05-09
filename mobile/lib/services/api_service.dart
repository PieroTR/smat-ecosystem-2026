import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/estacion.dart'; // Asumiendo que tienes tu modelo creado
import 'auth_service.dart';

class ApiService {
  // Configurado para Chrome
  final String baseUrl = "http://localhost:8000";

Future<List<Estacion>> fetchEstaciones() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/estaciones/"),
        // Añadimos headers explícitos para Chrome
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
        return []; // Retornamos lista vacía en lugar de error para no romper la UI
      }
    } catch (e) {
      print("Error de conexión: $e");
      return [];
    }
  }

  // Nueva función del Laboratorio 6.2 para enviar datos protegidos
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
}