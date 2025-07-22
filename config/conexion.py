import serial
import json
import re
import os
import sys
from datetime import datetime

# ========================
# Configuración de rutas
# ========================
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
JSON_PATH = os.path.join(SCRIPT_DIR, "datos_juego.json")

# ========================
# Inicialización de datos
# ========================
datos = {
    "estado_carrera": "esperando",  # esperando, contando, en_progreso, terminada
    "ganador": None,
    "vueltas_totales": None,
    "jugadores": {
        "1": {"vuelta_actual": 0, "posicion": 0, "velocidad": 0.0, "distancia": 0.0},
        "2": {"vuelta_actual": 0, "posicion": 0, "velocidad": 0.0, "distancia": 0.0}
    },
    "ultima_actualizacion": None
}

# ========================
# Guardado de JSON
# ========================
def guardar_json():
    datos["ultima_actualizacion"] = datetime.now().isoformat()
    with open(JSON_PATH, "w") as archivo:
        json.dump(datos, archivo, indent=2)
    print(f"[DEBUG] JSON actualizado a las {datos['ultima_actualizacion']}")

# ========================
# Procesamiento de línea
# ========================
def procesar_linea(linea):
    linea = linea.strip()

    if not linea:
        return

    print(f"[RAW] Recibido: {linea}")

    if linea.startswith("Vueltas seleccionadas:"):
        match = re.search(r"Vueltas seleccionadas:\s*(\d+)", linea)
        if match:
            datos["vueltas_totales"] = int(match.group(1))
            datos["estado_carrera"] = "esperando"
            print(f"[INFO] Vueltas totales: {datos['vueltas_totales']}")
            guardar_json()
        else:
            print(f"[WARN] No se pudo extraer número de vueltas de: {linea}")

    elif linea.startswith("p") and "," in linea:
        try:
            header, posicion_str = linea.split(",")
            if len(header) < 4:
                print(f"[WARN] Encabezado inválido: {header}")
                return

            jugador = header[1]
            vuelta = header[3]

            if not jugador.isdigit() or not vuelta.isdigit() or not posicion_str.strip().isdigit():
                print(f"[WARN] Datos no válidos en línea: {linea}")
                return

            posicion = int(posicion_str.strip())
            vuelta = int(vuelta)

            if jugador in datos["jugadores"]:
                datos["jugadores"][jugador]["vuelta_actual"] = vuelta
                datos["jugadores"][jugador]["posicion"] = posicion

                if vuelta > 0 and datos["estado_carrera"] == "esperando":
                    datos["estado_carrera"] = "en_progreso"

                if datos["vueltas_totales"] and vuelta >= datos["vueltas_totales"]:
                    datos["estado_carrera"] = "terminada"
                    datos["ganador"] = jugador

                print(f"[INFO] Jugador {jugador}: vuelta {vuelta}, posición {posicion}")
                guardar_json()
        except Exception as e:
            print(f"[ERROR] Error procesando línea de posición: {linea} - {str(e)}")

    elif linea.startswith("s") and "," in linea:
        try:
            jugador = linea[1]
            velocidad_str = linea.split(",")[1].strip()
            velocidad = float(velocidad_str)

            if jugador in datos["jugadores"]:
                datos["jugadores"][jugador]["velocidad"] = velocidad
                print(f"[INFO] Jugador {jugador}: velocidad {velocidad}")
                guardar_json()
        except Exception as e:
            print(f"[ERROR] Error procesando línea de velocidad: {linea} - {str(e)}")

    elif linea.startswith("d") and "," in linea:
        try:
            jugador = linea[1]
            distancia_str = linea.split(",")[1].strip()
            distancia = float(distancia_str)

            if jugador in datos["jugadores"]:
                datos["jugadores"][jugador]["distancia"] = distancia
                print(f"[INFO] Jugador {jugador}: distancia {distancia}")
                guardar_json()
        except Exception as e:
            print(f"[ERROR] Error procesando línea de distancia: {linea} - {str(e)}")

    elif linea.startswith("w"):
        jugador = linea[1]
        if jugador in datos["jugadores"]:
            datos["estado_carrera"] = "terminada"
            datos["ganador"] = jugador
            print(f"[INFO] Jugador {jugador} ha ganado la carrera.")
            guardar_json()
        else:
            print(f"[WARN] Jugador inválido en línea de ganador: {linea}")

# ========================
# Configuración de Arduino o stdin
# ========================
os.chdir(SCRIPT_DIR)

if len(sys.argv) < 2:
    print("[INFO] Sin puerto proporcionado, usando entrada estándar (stdin) para pruebas.")
    arduino = sys.stdin
else:
    puerto = sys.argv[1]
    try:
        arduino = serial.Serial(puerto, 115200, timeout=1)
        print(f"[INFO] Conectado al puerto {puerto} a 115200 baud.")
    except serial.SerialException:
        print(f"[ERROR] No se pudo abrir el puerto {puerto}")
        sys.exit(1)

# ========================
# Bucle principal
# ========================
try:
    while True:
        try:
            if isinstance(arduino, serial.Serial):
                linea = arduino.readline().decode('utf-8', errors='ignore').strip()
            else:
                linea = arduino.readline().strip()
                if isinstance(linea, bytes):
                    linea = linea.decode('utf-8', errors='ignore').strip()
        except Exception as e:
            print(f"[ERROR] Error leyendo línea: {str(e)}")
            continue

        if linea:
            procesar_linea(linea)

except KeyboardInterrupt:
    if isinstance(arduino, serial.Serial):
        arduino.close()
    print("[EXIT] Script terminado correctamente.")
