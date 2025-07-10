import serial
import json
import re
import os
import sys

# Establecer la carpeta del ejecutable como directorio de trabajo
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# Verificar argumento de línea de comandos
if len(sys.argv) < 2:
    print("[ERROR] Debes proporcionar el puerto como argumento. Ejemplo: conexion.exe COM3")
    sys.exit(1)

puerto = sys.argv[1]

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
        "1": {"vuelta_actual": 0, "posicion": 0, "velocidad": 0.0, "distancia": 0.0},
        "2": {"vuelta_actual": 0, "posicion": 0, "velocidad": 0.0, "distancia": 0.0}
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

        elif linea.startswith("s") and "," in linea:  # Ej: s1,1.42
            try:
                jugador, velocidad = linea[1], float(linea.split(",")[1])
                if jugador in datos["jugadores"]:
                    datos["jugadores"][jugador]["velocidad"] = velocidad
                    print(f"[INFO] Jugador {jugador}: velocidad {velocidad}")
                    guardar_json()
            except:
                print(f"[ERROR] Línea no válida de velocidad: {linea}")

        elif linea.startswith("d") and "," in linea:  # Ej: d1,320.5
            try:
                jugador, distancia = linea[1], float(linea.split(",")[1])
                if jugador in datos["jugadores"]:
                    datos["jugadores"][jugador]["distancia"] = distancia
                    print(f"[INFO] Jugador {jugador}: distancia {distancia}")
                    guardar_json()
            except:
                print(f"[ERROR] Línea no válida de distancia: {linea}")

except KeyboardInterrupt:
    arduino.close()
    print("[EXIT] Puerto cerrado. Script terminado.")
