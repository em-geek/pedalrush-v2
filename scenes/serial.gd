extends Control

const CONFIG_PATH := "res://config/dist/config.txt"

func _ready():
	cargar_config()


func cargar_config():
	if FileAccess.file_exists(CONFIG_PATH):
		var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
		var contenido = file.get_as_text().strip_edges()
		file.close()

		# Si usas solo el valor (ej. COM4)
		$VBoxContainer/PuertoLineEdit.text = contenido

		# Si usas formato tipo "puerto=COM4"
		# var partes = contenido.split("=")
		# if partes.size() == 2:
		#     $PuertoLineEdit.text = partes[1]

func guardar_config():
	var nuevo_puerto = $VBoxContainer/PuertoLineEdit.text.strip_edges()

	var file = FileAccess.open(CONFIG_PATH, FileAccess.WRITE)
	file.store_string(nuevo_puerto + "\n")  # o "puerto=" + nuevo_puerto + "\n" si usas ese formato
	file.close()

	print("Puerto actualizado a:", nuevo_puerto)



func _on_save_pressed() -> void:
	guardar_config()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
