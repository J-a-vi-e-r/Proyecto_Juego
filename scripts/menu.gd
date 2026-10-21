extends Control

# =============================================================
# MENU.GD — Menú principal
# =============================================================
# Maneja los botones del menú de inicio. Las funciones de abajo
# están conectadas a las señales 'pressed' de cada botón desde
# el Inspector de Godot (panel Nodo > Señales).
# =============================================================

# Se activa cuando el jugador hace clic en el botón "Jugar"
func _on_jugar_pressed() -> void:
	# Reemplaza la escena actual por la del mundo del juego.
	# change_scene_to_file descarga la escena actual de la memoria
	# y carga la nueva, evitando que ambas coexistan.
	get_tree().change_scene_to_file("res://escenas/Mundo.tscn")

# Se activa cuando el jugador hace clic en el botón "Salir"
func _on_salir_pressed() -> void:
	# Cierra por completo la ventana del juego y finaliza la ejecución
	get_tree().quit()
