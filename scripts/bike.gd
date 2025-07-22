extends Node2D

# Configuración
@export var LAPS_TO_WIN := 3
const TRACK_LENGTH = 1150
const CALORIES_PER_UNIT: float = 0.1
const SMOOTH_FACTOR := 8.0

# Variables
var total_distance: float = 0.0
var total_calories: float = 0.0
var finished = false
var player_id := 1

const MAX_SPEED = 1000  # Velocidad máxima estimada
const DECELERATION = 10 # No se usa directamente ya que se estima la velocidad

signal race_finished(is_winner: bool)
signal position_changed(new_position: Vector2)

var speed = 0.0
var previous_distance = 0.0
var display_distance = 0.0
var laps = 0

func _ready():
	$AnimatedSprite2D.play("idle")

func update_from_json(data: Dictionary):
	if finished:
		return

	# Actualizar datos desde JSON
	var nueva_pos = data.get("posicion", 0)
	var nueva_vuelta = data.get("vuelta_actual", 0)
	var nueva_velocidad = data.get("velocidad", 0.0)
	var nueva_distancia = data.get("distancia", 0.0)

	# Calcular distancia total
	if nueva_distancia > 0:
		total_distance = nueva_distancia
	else:
		total_distance = nueva_vuelta * TRACK_LENGTH + (nueva_pos / 100.0 * TRACK_LENGTH)

	total_calories = total_distance * CALORIES_PER_UNIT

	# Actualizar animación según velocidad
	update_animation(nueva_velocidad)

	# Verificar si ganó
	if nueva_vuelta >= LAPS_TO_WIN and not finished:
		finish(true)

func _process(delta):
	if finished:
		return

	# Movimiento suave de la posición x
	display_distance = lerp(display_distance, total_distance, delta * SMOOTH_FACTOR)
	var nueva_x = fmod(display_distance, TRACK_LENGTH)
	position.x = nueva_x

	# Estimar velocidad en función del cambio de distancia
	var distancia_diferencia = abs(display_distance - previous_distance)
	speed = distancia_diferencia / delta
	previous_distance = display_distance

func update_animation(speed: float):
	var anim = $AnimatedSprite2D

	if speed < 0.5:
		anim.play("idle")
	elif speed < 2.0:
		anim.play("pedal_slow")
	elif speed < 4.0:
		anim.play("pedal_mid")
	elif speed < 6.0:
		anim.play("pedal_fast")
	else:
		anim.play("pedal_fastest")

func finish(is_winner: bool):
	if finished:
		return

	finished = true
	speed = 0
	if is_winner:
		$AnimatedSprite2D.play("winner")
	else:
		$AnimatedSprite2D.play("loser")
	emit_signal("race_finished", is_winner)
