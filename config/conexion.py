import serial
import json
import re
import os

# Lee el puerto desde config.txt
with open("config.txt", "r") as f:
    puerto = f.read().strip()

# Intenta abrir el puerto
try:
    arduino = serial.Serial(puerto, 115200, timeout=1)
except serial.SerialException:
    print(f"[ERROR] No se pudo abrir el puerto {puerto}")
    exit(1)

# Inicialización del JSON
datos = {
    "vueltas_totales": None,
    "jugadores": {
        "1": {"vuelta_actual": 0, "posicion": 0},
        "2": {"vuelta_actual": 0, "posicion": 0}
    }
}

def guardar_json():
    with open("datos_juego.json", "w") as archivo:
        json.dump(datos, archivo, indent=2)

try:
    while True:
        linea = arduino.readline().decode('utf-8', errors='ignore').strip()

        if linea.startswith("Vueltas seleccionadas:"):
            match = re.search(r"Vueltas seleccionadas:\s*(\d+)", linea)
            if match:
                datos["vueltas_totales"] = int(match.group(1))
                print(f"[INFO] Vueltas totales: {datos['vueltas_totales']}")
                guardar_json()

        elif linea.startswith("p") and "," in linea:
            try:
                header, posicion = linea.split(",")
                jugador = header[1]
                vuelta = header[3]
                posicion = int(posicion)

                if jugador in datos["jugadores"]:
                    datos["jugadores"][jugador]["vuelta_actual"] = int(vuelta)
                    datos["jugadores"][jugador]["posicion"] = posicion
                    print(f"[INFO] Jugador {jugador}: vuelta {vuelta}, posición {posicion}")
                    guardar_json()
            except Exception as e:
                print(f"[ERROR] Línea no válida: {linea}")

except KeyboardInterrupt:
    arduino.close()
    print("[EXIT] Puerto cerrado. Script terminado.")
