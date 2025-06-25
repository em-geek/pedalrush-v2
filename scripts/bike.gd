extends Node2D

const MAX_SPEED = 1000  # Velocidad máxima
const ACCELERATION = 150  # Aceleración por pulsación
const DECELERATION = 10 # Pérdida de velocidad con el tiempo

@export var pedal_action: String = "boton_a"
signal position_changed(new_position: Vector2)

var speed = 0  # Velocidad actual
var pedaling = false  # Si se está pedaleando
var finished = false  # Flag para saber si la carrera ya terminó

var laps = 0
const LAPS_TO_WIN = 3
const TRACK_LENGTH = 1150
const MAX_DISTANCE = LAPS_TO_WIN * TRACK_LENGTH

signal race_finished(is_winner: bool)

var total_distance: float = 0.0
var total_calories: float = 0.0
const CALORIES_PER_UNIT: float = 0.1

@export var player_id := 1  # 1, 2, 3, 4

func _ready():
	$AnimatedSprite2D.play("idle")  # Estado inicial en idle


func update_from_json(data: Dictionary):
	if finished:
		return

	if !data.has(str(player_id)):
		return
	
	var player_data = data[str(player_id)]
	var nueva_pos = player_data.get("posicion", 0)
	var nueva_vuelta = player_data.get("vuelta_actual", 0)

	# Distancia = vueltas completas + posición actual
	total_distance = nueva_vuelta * TRACK_LENGTH + (nueva_pos / 100.0 * TRACK_LENGTH)
	total_calories = total_distance * CALORIES_PER_UNIT
	laps = nueva_vuelta

	position.x = fmod(total_distance, TRACK_LENGTH)

	if laps >= LAPS_TO_WIN:
		finish(true)

	update_animation()


func update_animation():
	var anim = $AnimatedSprite2D

	if speed == 0:
		anim.play("idle")
	elif speed < MAX_SPEED / 4:
		anim.play("pedal_slow")
	elif speed < MAX_SPEED / 2:
		anim.play("pedal_mid")
	elif speed < MAX_SPEED / 1.1:
		anim.play("pedal_fast")
	else:
		anim.play("pedal_fastest")
		
# Función para detener la bicicleta y reproducir la animación final
func finish(is_winner: bool):
	if finished:  # Evitar múltiples llamadas
		return

	finished = true
	speed = 0
	if is_winner:
		$AnimatedSprite2D.play("winner")
	else:
		$AnimatedSprite2D.play("loser")
	emit_signal("race_finished", is_winner)
		


func _on_area_2d_area_entered(area: Area2D) -> void:
	pass # Replace with function body.
