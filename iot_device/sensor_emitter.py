import random
import time
import requests

# CONFIGURACIÓN
API_URL = "http://localhost:8000/lecturas/"  # <-- CORREGIDO: Con barra al final
ESTACION_ID = 1  # ID de la estación registrada en tu DB
TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbl9maXNpIiwiZXhwIjoxNzc5ODk5NjEyfQ.dpSIJHuascM1HvBzUMA9CqhnsJFOHnY5MrUxJEcBsQg"


def leer_sensor_emulado():
    """Simula la lectura física del nivel del río en centímetros."""
    return round(random.uniform(10.5, 85.0), 2)


def enviar_telemetria():
    print(f"--- Iniciando Emisor IoT para Estación ({ESTACION_ID}) ---")

    while True:
        # Generar la lectura emulada del sensor
        valor = leer_sensor_emulado()

        # Construir el payload y los headers de autenticación
        payload = {"valor": valor, "estacion_id": ESTACION_ID}
        headers = {"Authorization": f"Bearer {TOKEN}"}

        # --- RETO: Lógica de Alarma e Intervalo Dinámico ---
        if valor > 70.0:
            print(f"[ALERTA] Umbral de inundación superado. Valor: {valor} cm")
            tiempo_espera = 2  # Modo de Emergencia (2 segundos)
        else:
            tiempo_espera = 10  # Modo Normal (10 segundos)

        # Intento de envío de datos al backend mediante HTTP POST
        try:
            response = requests.post(
                API_URL, json=payload, headers=headers, timeout=5
            )

            # Validar que el backend recibió los datos con éxito (200 OK o 201 Created)
            if response.status_code in [200, 201]:
                print(f"[OK] Lectura enviada con éxito: {valor} cm")
            else:
                print(
                    f"[ERROR] Código de estado del servidor: {response.status_code}"
                )

        except Exception as e:
            print(f"[CRÍTICO] No hay conexión con el servidor: {e}")

        # Aplicar el tiempo de espera dinámico antes de la siguiente lectura
        time.sleep(tiempo_espera)


# Punto de entrada para ejecutar el script
if __name__ == "__main__":
    enviar_telemetria()