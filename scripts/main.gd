extends Node2D

@onready var bikes = [
	$Bikes/Bike1,
	$Bikes/Bike2,
	$Bikes/Bike3,
	$Bikes/Bike4
]

@onready var calorias_labels = [
	$BottomPanel/StatsPanel/CaloriasPanel/Calorias1,
	$BottomPanel/StatsPanel/CaloriasPanel/Calorias2,
	$BottomPanel/StatsPanel/CaloriasPanel/Calorias3,
	$BottomPanel/StatsPanel/CaloriasPanel/Calorias4
]

@onready var distancia_labels = [
	$BottomPanel/StatsPanel/DistanciaPanel/Distancia1,
	$BottomPanel/StatsPanel/DistanciaPanel/Distancia2,
	$BottomPanel/StatsPanel/DistanciaPanel/Distancia3,
	$BottomPanel/StatsPanel/DistanciaPanel/Distancia4
]

@onready var posicion_labels = [
	$BottomPanel/StatsPanel/PosicionPanel/Posicion1,
	$BottomPanel/StatsPanel/PosicionPanel/Posicion2,
	$BottomPanel/StatsPanel/PosicionPanel/Posicion3,
	$BottomPanel/StatsPanel/PosicionPanel/Posicion4
]

var distancias = [0, 0, 0, 0]
var calorias = [0, 0, 0, 0]
var race_finished = false

var json_path := "res://config/dist/datos_juego.json"  # donde se guarda el JSON
var json_data: Dictionary = {}


func _process(_delta):
	for i in range(bikes.size()):
		# Usamos la distancia total acumulada
		var distancia_actual = int(bikes[i].total_distance)
		var calorias_actual = int(bikes[i].total_calories)

		distancias[i] = distancia_actual
		calorias[i] = calorias_actual

		distancia_labels[i].text = "Bici %d: %d m" % [i + 1, distancia_actual]
		calorias_labels[i].text = "Bici %d: %d cal" % [i + 1, calorias_actual]
		posicion_labels[i].text = "Bici %d: %d/%d vueltas" % [i+1, int(bikes[i].total_distance/1150), bikes[i].LAPS_TO_WIN]

	actualizar_posiciones()
		# Cargar JSON si existe
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var parsed = JSON.parse_string(content)
		if parsed and typeof(parsed) == TYPE_DICTIONARY:
			json_data = parsed.get("jugadores", {})

			for i in range(bikes.size()):
				bikes[i].update_from_json(json_data)


	if race_finished:
		return


func _ready():
	# Asignar controles a cada bicicleta
	bikes[0].player_id = 1
	bikes[1].player_id = 2
	bikes[2].player_id = 3
	bikes[3].player_id = 4

	for bike in bikes:
		bike.connect("race_finished", _on_bike_race_finished)

# En el main.gd, modifica actualizar_posiciones() así:
func actualizar_posiciones():
	var distancias_con_indices = []
	for i in range(bikes.size()):
	# Usamos total_distance para determinar la posición
		distancias_con_indices.append([i, bikes[i].total_distance])  

	# Orden descendente (mayor distancia = primero)
	distancias_con_indices.sort_custom(func(a, b): return a[1] > b[1])

	for pos in range(distancias_con_indices.size()):
		var bici_index = distancias_con_indices[pos][0]
		posicion_labels[bici_index].text = "Bici %d: %d°" % [bici_index+1, pos+1]

		# Cambiar color según posición
		if pos == 0:
			posicion_labels[bici_index].modulate = Color.GOLD
		elif pos == 1:
			posicion_labels[bici_index].modulate = Color.SILVER
		elif pos == 2:
			posicion_labels[bici_index].modulate = Color.WHITE
		else:
			posicion_labels[bici_index].modulate = Color.PALE_VIOLET_RED

func _on_bike_race_finished(is_winner: bool):
	if race_finished:  # Si ya terminó la carrera, ignorar
		return

	if is_winner:
		race_finished = true
	# Detener todas las bicicletas y mostrar animaciones
	for bike in bikes:
		if bike != bikes[0]:  # bikes[0] es la que ganó en este ejemplo
			bike.finish(false)

	# Opcional: Mostrar mensaje de victoria
	#$UI/MessageLabel.text = "¡Carrera terminada!"
	#$UI/MessageLabel.visible = true

	# Opcional: Deshabilitar controles
	set_process_input(false)
