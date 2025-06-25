extends Control

# Ruta al ejecutable (ajústalo según dónde lo pongas en el exportado)
const EXE_PATH := "res://config/dist/conexion.exe"

# Tiempo máximo de espera si no deseas esperar la respuesta del proceso
const TIEMPO_ESPERA := 3.0

var proceso

@onready var salida_label = $VBoxContainer/Salida  # Ajusta la ruta según tu escena


func _ready():
	mostrar_mensaje("Iniciando conexión con Arduino...")
	await get_tree().create_timer(0.5).timeout
	ejecutar_lector()

func mostrar_mensaje(texto):
	$VBoxContainer/Label.text = texto

func ejecutar_lector():
	var destino = EXE_PATH
	if not FileAccess.file_exists(destino):
		var archivo = FileAccess.open(EXE_PATH, FileAccess.READ)
		var contenido = archivo.get_buffer(archivo.get_length())
		archivo.close()
		var archivo_nuevo = FileAccess.open(destino, FileAccess.WRITE)
		archivo_nuevo.store_buffer(contenido)
		archivo_nuevo.close()

	mostrar_mensaje("Ejecutando lector...")

	var output = []
	var result = OS.execute(ProjectSettings.globalize_path(destino), [], output, false)

	if result == OK:
		mostrar_mensaje("Datos recibidos")
		var salida_texto = ""
		for linea in output:
			salida_texto += linea + "\n"
		salida_label.text = salida_texto  # ⬅ Aquí mostramos la salida en el Label
		await get_tree().create_timer(TIEMPO_ESPERA).timeout
		cambiar_a_escena_principal()
	else:
		salida_label.text = "Error al ejecutar lector (código: %d)" % result
		

func cambiar_a_escena_principal():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
