extends Node2D

# Configuración
var json_path := "res://config/dist/datos_juego.json"
var json_check_timer := 0.0
var json_check_interval := 0.1  # Revisar cada 100ms

# Estados
enum EstadoCarrera {ESPERANDO, CONTANDO, EN_PROGRESO, TERMINADA}
var estado_carrera := EstadoCarrera.ESPERANDO
var ganador := -1
var vueltas_totales := 3

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

var json_data: Dictionary = {}
var carrera_iniciada := false

func _process(delta):
	json_check_timer += delta
	if json_check_timer >= json_check_interval:
		json_check_timer = 0.0
		actualizar_datos_carrera()
		

func actualizar_datos_carrera():
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		return
	
	var content = file.get_as_text()
	var parsed = JSON.parse_string(content)
	
	if not parsed or typeof(parsed) != TYPE_DICTIONARY:
		return
	
	# Actualizar vueltas totales
	if parsed.get("vueltas_totales", vueltas_totales) != vueltas_totales:
		vueltas_totales = parsed["vueltas_totales"]
		for bike in bikes:
			bike.LAPS_TO_WIN = vueltas_totales
	
	# Actualizar estado de la carrera
	match parsed.get("estado_carrera", "esperando"):
		"esperando":
			estado_carrera = EstadoCarrera.ESPERANDO
		"contando":
			estado_carrera = EstadoCarrera.CONTANDO
		"en_progreso":
			if estado_carrera != EstadoCarrera.EN_PROGRESO:
				iniciar_carrera()
			estado_carrera = EstadoCarrera.EN_PROGRESO
		"terminada":
			if estado_carrera != EstadoCarrera.TERMINADA:
				finalizar_carrera(int(parsed.get("ganador", 1)))
			estado_carrera = EstadoCarrera.TERMINADA
	
	# Actualizar datos de jugadores
	if parsed.has("jugadores"):
		var jugadores_data = parsed["jugadores"]
		for i in range(bikes.size()):
			var player_id = str(i+1)
			if jugadores_data.has(player_id):
				bikes[i].update_from_json(jugadores_data[player_id])

func iniciar_carrera():
	print("¡Carrera iniciada!")
	$UI/MessageLabel.text = "¡Carrera iniciada!"
	$UI/MessageLabel.visible = true
	await get_tree().create_timer(2.0).timeout
	$UI/MessageLabel.visible = false

func finalizar_carrera(ganador_id: int):
	if ganador_id == ganador:  # Evitar múltiples finalizaciones
		return

	ganador = ganador_id

	for i in range(bikes.size()):
		bikes[i].finish(i + 1 == ganador_id)

	$UI/MessageLabel.text = "¡Carrera terminada!\nGanador: Jugador %d" % ganador_id
	$UI/MessageLabel.visible = true

func _ready():
	# Configuración inicial de bicicletas
	for i in range(bikes.size()):
		bikes[i].player_id = i + 1
		bikes[i].connect("race_finished", _on_bike_race_finished)

	# Iniciar temporizador para verificar JSON
	set_process(true)

func cargar_configuracion_inicial():
	var config_path = "user://config.txt"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var content = file.get_as_text().strip_edges()
			# Puedes añadir lógica para leer configuraciones adicionales si las necesitas


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
