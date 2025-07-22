import time
import random
import sys

# ==============================
# Configuración de simulación
# ==============================
VUELTAS = 3
TIEMPO_ENTRE_DATOS = 0.5  # segundos
TIEMPO_ENTRE_CARRERAS = 5  # segundos

# ==============================
# Función de simulación
# ==============================
def simular_arduino():
    # Enviar vueltas seleccionadas
    print(f"Vueltas seleccionadas: {VUELTAS}", flush=True)
    time.sleep(1)

    for vuelta in range(1, VUELTAS + 1):
        for jugador in ['1', '2']:
            posicion = random.randint(1, 100)
            velocidad = round(random.uniform(0.5, 2.0), 2)
            distancia = round(vuelta * 100 + random.uniform(0, 50), 2)

            # Datos de posición
            print(f"p{jugador}1{vuelta},{posicion}", flush=True)
            # Datos de velocidad
            print(f"s{jugador},{velocidad}", flush=True)
            # Datos de distancia
            print(f"d{jugador},{distancia}", flush=True)

            time.sleep(TIEMPO_ENTRE_DATOS)

    # Enviar ganador aleatorio
    ganador = random.choice(['1', '2'])
    print(f"w{ganador}", flush=True)

# ==============================
# Bucle principal de simulación
# ==============================
if __name__ == "__main__":
    try:
        while True:
            simular_arduino()
            time.sleep(TIEMPO_ENTRE_CARRERAS)
    except KeyboardInterrupt:
        print("[EXIT] Simulación finalizada correctamente.")
        sys.exit(0)
