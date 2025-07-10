extends Control

const EXE_ORIGEN := "res://config/dist/conexion.exe"
const EXE_PATH := "user://conexion.exe"
const CONFIG_ORIGEN := "res://config/config.txt"
const CONFIG_PATH := "user://config.txt"
const TIEMPO_ESPERA := 3.0

@onready var salida_label = $VBoxContainer/Salida

func _ready():
	mostrar_mensaje("Iniciando conexión con Arduino...")
	copiar_exe_a_user()
	copiar_config_a_user()
	await get_tree().create_timer(0.5).timeout
	ejecutar_lector()

func mostrar_mensaje(texto):
	$VBoxContainer/Label.text = texto

func copiar_exe_a_user():
	if not FileAccess.file_exists(EXE_PATH):
		var archivo_origen = FileAccess.open(EXE_ORIGEN, FileAccess.READ)
		if archivo_origen:
			var contenido = archivo_origen.get_buffer(archivo_origen.get_length())
			archivo_origen.close()
			var archivo_destino = FileAccess.open(EXE_PATH, FileAccess.WRITE)
			archivo_destino.store_buffer(contenido)
			archivo_destino.close()
			print("EXE copiado correctamente a user://")
		else:
			print("Error: No se pudo abrir el EXE original en res://")

func copiar_config_a_user():
	if not FileAccess.file_exists(CONFIG_PATH):
		var archivo_origen = FileAccess.open(CONFIG_ORIGEN, FileAccess.READ)
		if archivo_origen:
			var contenido = archivo_origen.get_buffer(archivo_origen.get_length())
			archivo_origen.close()
			var archivo_destino = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
			archivo_destino.store_buffer(contenido)
			archivo_destino.close()
			print("config.txt copiado correctamente a user://")
		else:
			print("Error: No se pudo abrir config.txt en res://")

func ejecutar_lector():
	mostrar_mensaje("Ejecutando lector...")

	# Leer el puerto desde user://config.txt
	var puerto := ""
	if FileAccess.file_exists(CONFIG_PATH):
		var archivo_config = FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if archivo_config:
			puerto = archivo_config.get_as_text().strip_edges()
			archivo_config.close()
		else:
			var error_msg = "No se pudo leer el archivo de configuración."
			salida_label.text = error_msg
			print(error_msg)
			return
	else:
		var error_msg = "Archivo de configuración no encontrado en: %s" % CONFIG_PATH
		salida_label.text = error_msg
		print(error_msg)
		return

	# Ejecutar el EXE con el argumento del puerto
	var output = []
	var result = OS.execute(
		ProjectSettings.globalize_path(EXE_PATH),
		[puerto],
		output,
		true
	)

	if result == OK:
		var salida_texto := ""
		for linea in output:
			salida_texto += linea + "\n"
		salida_label.text = salida_texto
		await get_tree().create_timer(TIEMPO_ESPERA).timeout
		cambiar_a_escena_principal()
	else:
		var salida_texto := ""
		for linea in output:
			salida_texto += linea + "\n"
		var texto_error := "Error al ejecutar lector (código: %d)\nRuta: %s\nPuerto: %s\nSalida:\n%s" % [result, EXE_PATH, puerto, salida_texto]
		salida_label.text = texto_error
		print(texto_error)
		await get_tree().create_timer(5).timeout
		get_tree().change_scene_to_file("res://scenes/menu.tscn")


func cambiar_a_escena_principal():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
