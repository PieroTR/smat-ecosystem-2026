### Comunicación Segura mediante Token JWT

Para garantizar la integridad y seguridad de la telemetría, el hardware emulado (`sensor_emitter.py`) se comunica con la nube de la siguiente manera:

1. **Autenticación Inicial:** El script de Python realiza una petición `POST` al endpoint `/token` enviando las credenciales correspondientes. El backend valida los datos y le responde con un token de acceso JWT (`access_token`).
2. **Inclusión del Token:** El script almacena este token en memoria y lo adjunta automáticamente en la cabecera HTTP (`Authorization: Bearer <TOKEN>`) de cada petición posterior.
3. **Registro Protegido:** Cada vez que el sensor envía una lectura mediante `POST /lecturas/`, el backend intercepta la cabecera, valida que el JWT sea auténtico y vigente, y solo entonces permite registrar el valor en la base de datos. Si el token falta o es inválido, la lectura es rechazada con un error `401 Unauthorized`.