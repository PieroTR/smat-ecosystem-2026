import 'dart:async'; // Necesario para usar el Timer
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/estacion.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Estacion>> futureEstaciones;
  final ApiService apiService = ApiService();
  Timer? _timer; // <-- Guardamos la referencia del Timer para poder destruirlo después

  @override
  void initState() {
    super.initState();
    futureEstaciones = apiService.fetchEstaciones();

    // --- AUTOMATIZACIÓN: Refresca la pantalla automáticamente cada 3 segundos ---
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      refrescarDatos();
    });
  }

  @override
  void dispose() {
    // --- BUENA PRÁCTICA: Cancelamos el timer cuando salgamos de esta pantalla ---
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refrescarDatos() async {
    // Verificamos si el widget sigue montado antes de actualizar el estado
    if (!mounted) return;
    setState(() {
      futureEstaciones = apiService.fetchEstaciones();
    });
  }

  void _mostrarDialogoCreacion() {
    final nombreCtrl = TextEditingController();
    final ubicacionCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nueva Estación"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: ubicacionCtrl,
              decoration: const InputDecoration(labelText: "Ubicación"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              bool ok = await apiService.crearEstacion(
                nombreCtrl.text,
                ubicacionCtrl.text,
              );
              if (ok) {
                if (!mounted) return;
                Navigator.pop(context);
                refrescarDatos();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Estación creada con éxito")),
                );
              }
            },
            child: const Text("Crear"),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEdicion(Estacion estacion) {
    final nombreCtrl = TextEditingController(text: estacion.nombre);
    final ubicacionCtrl = TextEditingController(text: estacion.ubicacion);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Editar Estación"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),
            TextField(
              controller: ubicacionCtrl,
              decoration: const InputDecoration(labelText: "Ubicación"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              bool ok = await apiService.editarEstacion(
                estacion.id,
                nombreCtrl.text,
                ubicacionCtrl.text,
              );
              if (ok) {
                if (!mounted) return;
                Navigator.pop(context);
                refrescarDatos();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Estación actualizada")),
                );
              }
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMAT - Monitoreo Móvil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoCreacion,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: refrescarDatos,
        child: FutureBuilder<List<Estacion>>(
          future: futureEstaciones,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.grey, size: 64),
                    const SizedBox(height: 16),
                    Text('${snapshot.error}', textAlign: TextAlign.center),
                    TextButton(
                      onPressed: refrescarDatos,
                      child: const Text("Reintentar"),
                    )
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No hay estaciones registradas'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final est = snapshot.data![index];

                  return Dismissible(
                    key: Key(est.id.toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) async {
                      bool ok = await apiService.eliminarEstacion(est.id);
                      if (ok) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${est.nombre} eliminada")),
                        );
                      } else {
                        refrescarDatos();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Error al eliminar")),
                        );
                      }
                    },
                    child: Card(
                      // --- RETO SEMANA 9: Fondo rojo suave si supera los 70.0 cm ---
                      color: est.ultimoValor > 70.0
                          ? Colors.red.shade50
                          : Colors.white,
                      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: ListTile(
                        leading: Icon(
                          Icons.satellite_alt,
                          color: est.ultimoValor > 70.0 ? Colors.red : Colors.green,
                        ),
                        title: Text(
                          est.nombre,
                          style: TextStyle(
                            fontWeight: est.ultimoValor > 70.0 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text("${est.ubicacion} • Nivel: ${est.ultimoValor} cm"),
                        trailing: est.ultimoValor > 70.0
                            ? const Icon(Icons.warning, color: Colors.red)
                            : null,
                        onTap: () => _mostrarDialogoEdicion(est),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}