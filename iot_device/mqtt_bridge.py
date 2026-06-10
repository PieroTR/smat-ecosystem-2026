import paho.mqtt.client as mqtt
import requests
import json
import sys
import time  # Necesario para medir el criterio de reporte de vida mínimo

# =====================================================================
# CONFIGURACIÓN DEL ENTORNO SMAT
# =====================================================================
MQTT_BROKER = "broker.hivemq.com"
MQTT_PORT = 1883
MQTT_TOPIC = "fisi/smat/estaciones/+/lecturas"  # Wildcard '+' para capturar el ID de la estación [cite: 47]
API_URL = "http://localhost:8000/lecturas/"

# Token JWT generado previamente desde Swagger para el usuario administrador [cite: 49]
JWT_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJhZG1pbl9maXNpIiwiZXhwIjoxNzgxMTEyMzcyfQ.9TRcbQcXr7X93KfnJoBvvY5HGdIxqS2qjS22BqkC7u0"

# =====================================================================
# RETO SEMANA 11: MEMORIA CACHÉ LOCAL
# =====================================================================
# El Bridge lleva registro en un diccionario en memoria del último valor guardado por cada estación 
cache_estaciones = {}

# =====================================================================
# CALLBACKS DE MQTT
# =====================================================================
def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("✔ Conectado exitosamente al Broker MQTT", flush=True)
        # Suscribirse al tópico global de lecturas de estaciones [cite: 62, 63]
        client.subscribe(MQTT_TOPIC)
        print(f"📡 Escuchando transmisiones en el tópico: {MQTT_TOPIC}", flush=True)
    else:
        print(f"❌ Error de conexión al Broker. Código de retorno: {rc}", flush=True)
        sys.exit(1)

def on_message(client, userdata, msg):
    try:
        # 1. Decodificar el payload binario de MQTT a JSON string [cite: 68, 69]
        payload_raw = msg.payload.decode("utf-8")
        data_json = json.loads(payload_raw)
        
        # 2. Extraer el ID dinámico de la estación desde la estructura del tópico [cite: 71, 72]
        topic_parts = msg.topic.split('/')
        estacion_id = int(topic_parts[3])
        
        nuevo_valor = float(data_json["valor"])
        tiempo_actual = time.time()  # Timestamp actual en segundos
        
        print(f"\n📥 Telemetría recibida de Estación [{estacion_id}]: {nuevo_valor} cm", flush=True)

        # =================================================================
        # LÓGICA DEL FILTRO DE RUIDO (DEADBAND FILTER)
        # =================================================================
        debe_enviar = False
        razon = ""

        if estacion_id not in cache_estaciones:
            # Condición inicial: No hay registros previos en la caché local 
            debe_enviar = True
            razon = "Primer registro de la estación"
        else:
            ultimo_valor = cache_estaciones[estacion_id]["ultimo_valor"]
            ultima_hora = cache_estaciones[estacion_id]["ultima_hora"]
            
            # Calcular variación porcentual absoluta para evitar saturación de datos idénticos [cite: 124, 126]
            if ultimo_valor != 0:
                variacion = abs(nuevo_valor - ultimo_valor) / ultimo_valor
            else:
                variacion = abs(nuevo_valor - ultimo_valor)  # Evitar división por cero
                
            # Calcular tiempo transcurrido desde la última inserción exitosa
            tiempo_transcurrido = tiempo_actual - ultima_hora

            # Evaluar criterios del reto: variación > ±5% o > 60 segundos transcurridos [cite: 128]
            if variacion > 0.05:
                debe_enviar = True
                razon = f"Variación significativa ({variacion * 100:.2f}%)"
            elif tiempo_transcurrido > 60.0:
                debe_enviar = True
                razon = f"Reporte de vida mínimo (> 60s sin transmitir)"

        # =================================================================
        # PROCESAMIENTO DEL ENVÍO O BLOQUEO REQUERIDO
        # =================================================================
        if debe_enviar:
            print(f"🚀 [Filtro Aprobado] Enviando a FastAPI por: {razon}", flush=True)
            
            # 3. Formatear la carga útil para cumplir con el esquema de FastAPI [cite: 76]
            api_payload = {
                "valor": nuevo_valor,
                "estacion_id": estacion_id
            }
            
            # 4. Ingestión de datos segura mediante HTTP POST con Header Bearer Token [cite: 80]
            headers = {
                "Content-Type": "application/json",
                "Authorization": f"Bearer {JWT_TOKEN}"
            }
            
            response = requests.post(API_URL, json=api_payload, headers=headers, timeout=5)
            
            if response.status_code in [200, 201]:
                print(f"💾 [DB Sincronizada] Lectura de {nuevo_valor} cm guardada en SQLite.", flush=True)
                
                # Sincronizar la memoria caché local tras un guardado en la nube exitoso 
                cache_estaciones[estacion_id] = {
                    "ultimo_valor": nuevo_valor,
                    "ultima_hora": tiempo_actual
                }
            else:
                print(f"⚠️ [Fallo de Ingesta] API rechazó el dato. Código: {response.status_code} - {response.text}", flush=True)
        else:
            # Muestra en los logs cómo el Bridge bloquea las peticiones HTTP redundantes 
            print(f"🛑 [Filtro Activo] Dato redundante bloqueado para Estación [{estacion_id}].", flush=True)

    except KeyError as e:
        print(f"❌ Error de esquema: Falta la llave {e} en el payload MQTT.", flush=True)
    except ValueError:
        print("❌ Error de casteo: El valor o el ID de la estación no son numéricos.", flush=True)
    except Exception as e:
        print(f"💥 Error crítico en el Bridge: {e}", flush=True)

# =====================================================================
# INICIALIZACIÓN DEL CLIENTE DE RED MQTT
# =====================================================================
bridge_client = mqtt.Client()
bridge_client.on_connect = on_connect
bridge_client.on_message = on_message

try:
    print("🚀 Inicializando el Bridge de Acoplamiento SMAT...", flush=True)
    bridge_client.connect(MQTT_BROKER, MQTT_PORT, 60)
    
    # Mantener el hilo escuchando activamente de forma síncrona [cite: 110]
    bridge_client.loop_forever()
    
except KeyboardInterrupt:
    print("\n🛑 Bridge detenido por el administrador.", flush=True)
except Exception as e:
    print(f"💥 Error crítico al conectar el Bridge: {e}", flush=True)