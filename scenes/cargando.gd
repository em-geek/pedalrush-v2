extends Control

const EXE_ORIGEN := "res://config/dist/conexion.exe"
const EXE_PATH := "user://conexion.exe"
const CONFIG_ORIGEN := "res://config/config.txt"
const CONFIG_PATH := "user://config.txt"
const TIEMPO_ESPERA := 3.0
const TIMEOUT_CONEXION := 30.0 

@onready var salida_label = $VBoxContainer/Salida
@onready var timer_timeout := Timer.new()
var proceso_id := -1  # ID del proceso
var tiempo_inicio := 0.0

func _ready():
	add_child(timer_timeout)
	timer_timeout.timeout.connect(_on_timeout_conexion)
	
	mostrar_mensaje("Iniciando conexión con Arduino...")
	copiar_archivos_necesarios()
	await get_tree().create_timer(0.5).timeout  # Pequeña pausa para UI
	iniciar_lector()

func _process(delta):
	if proceso_id != -1:
		var exit_status = OS.get_process_exit_code(proceso_id)
		if exit_status != -1:  # Proceso terminado
			_manejar_resultado_lector(exit_status)

func _on_timeout_conexion():
	if proceso_id != -1:
		# Función correcta para Godot 4.3
		OS.kill(proceso_id)
		mostrar_error("Timeout: El lector excedió el tiempo de conexión")
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func copiar_archivos_necesarios():
	var errores := []
	
	if !FileAccess.file_exists(EXE_PATH):
		if !_copiar_archivo(EXE_ORIGEN, EXE_PATH):
			errores.append("No se pudo copiar conexion.exe")
	
	if !FileAccess.file_exists(CONFIG_PATH):
		if !_copiar_archivo(CONFIG_ORIGEN, CONFIG_PATH):
			errores.append("No se pudo copiar config.txt")
	
	if errores.size() > 0:
		mostrar_error("Errores:\n" + "\n".join(errores))
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _copiar_archivo(origen: String, destino: String) -> bool:
	var archivo_origen = FileAccess.open(origen, FileAccess.READ)
	if !archivo_origen:
		return false
	
	var contenido = archivo_origen.get_buffer(archivo_origen.get_length())
	archivo_origen.close()
	
	var archivo_destino = FileAccess.open(destino, FileAccess.WRITE)
	if !archivo_destino:
		return false
	
	archivo_destino.store_buffer(contenido)
	archivo_destino.close()
	return true

func iniciar_lector():
	mostrar_mensaje("Conectando con Arduino...")
	
	_leer_puerto_serial()
	# Nota: La espera se maneja dentro de _leer_puerto_serial

func _leer_puerto_serial():
	if !FileAccess.file_exists(CONFIG_PATH):
		mostrar_error("Archivo config.txt no encontrado")
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	
	var archivo = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if !archivo:
		mostrar_error("No se pudo leer config.txt")
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	
	var puerto = archivo.get_as_text().strip_edges()
	archivo.close()
	
	if puerto.is_empty():
		mostrar_error("Puerto no configurado en config.txt")
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	
	# Si llegamos aquí, tenemos un puerto válido
	tiempo_inicio = Time.get_ticks_msec()
	timer_timeout.start(TIMEOUT_CONEXION)
	
	proceso_id = OS.create_process(ProjectSettings.globalize_path(EXE_PATH), [puerto], false)
	
	if proceso_id == -1:
		mostrar_error("No se pudo iniciar el lector")
		await get_tree().create_timer(3.0).timeout
		get_tree().change_scene_to_file("res://scenes/menu.tscn")

func _manejar_resultado_lector(exit_code: int):
	timer_timeout.stop()
	
	if exit_code != 0:
		mostrar_error("Error en lector (Código %d)" % exit_code)
		await get_tree().create_timer(5.0).timeout
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
	else:
		salida_label.text = "Conexión exitosa"
		await get_tree().create_timer(TIEMPO_ESPERA).timeout
		cambiar_a_escena_principal()

func mostrar_mensaje(texto: String):
	$VBoxContainer/Label.text = texto
	salida_label.text = ""
	print(texto)

func mostrar_error(texto: String):
	$VBoxContainer/Label.text = "Error"
	salida_label.text = texto
	push_error(texto)

func cambiar_a_escena_principal():
	proceso_id = -1  # Resetear ID del proceso
	get_tree().change_scene_to_file("res://scenes/main.tscn")
