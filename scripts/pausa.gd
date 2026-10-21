extends CanvasLayer

# =============================================================
# PAUSA.GD
# =============================================================
# Controla el menú de pausa del juego. Usa CanvasLayer para que
# la UI de pausa siempre se dibuje encima de todo el juego,
# sin que la cámara ni otros elementos la afecten.
# =============================================================

# --- AL INICIAR EL JUEGO ---
func _ready():
	# El menú de pausa debe iniciar invisible para que no interrumpa el juego al arrancar
	visible = false

# --- DETECCIÓN DE ENTRADAS/TECLAS ---
# _input recibe todos los eventos de teclado/ratón antes que _process.
# Es el lugar ideal para detectar teclas globales como Escape.
func _input(event):
	# Si el jugador presiona el botón configurado como "ui_cancel" (por defecto es la tecla Escape)
	if event.is_action_pressed("ui_cancel"):
		# El operador '!' invierte el booleano: si era false pasa a true, y viceversa.
		# Esto hace que un mismo botón funcione como "pausar" y "reanudar" a la vez.
		visible = !visible
		
		# Sincronizamos el estado de pausa del motor con la visibilidad del menú.
		# get_tree().paused = true congela TODO el juego excepto los nodos marcados como "process_mode = Always".
		get_tree().paused = visible

# --- BOTÓN DE REGRESAR AL MENÚ ---
func _on_menu_pressed() -> void:
	# ¡IMPORTANTE! Si cambiamos de escena mientras get_tree().paused es true,
	# la nueva escena también arrancará pausada y el juego quedará congelado.
	# Siempre hay que desactivar la pausa antes de hacer un cambio de escena.
	get_tree().paused = false
	# Viajamos a la escena del menú de inicio
	get_tree().change_scene_to_file("res://escenas/Menu.tscn")

# --- BOTÓN DE SALIR ---
func _on_salir_pressed() -> void:
	# Cierra el juego por completo
	get_tree().quit()


# =========================================================================
# CONTROL DEL BOTÓN DE LA TRIVIA
# =========================================================================
# Esta función se activa automáticamente cuando el jugador hace clic
# en la pestaña "📝 Responder Trivia" que aparece en la pantalla.
# =========================================================================
func _on_boton_trivia_pressed():
	# 1. Ocultamos el botón para que no se quede dibujado encima de las preguntas
	Global.ocultar_boton_trivia()
	
	# 2. Reiniciamos el contador de fallos para que empiece limpio el intento
	Global.fallos = 0
	
	# 3. Congelamos las físicas y el movimiento del personaje usando la función Global
	Global.congelar_juego()
	
	# 4. Abrimos el diálogo directamente en la primera pregunta (saltándonos la confirmación inicial)
	DialogueManager.show_example_dialogue_balloon(load("res://Dialogos/Nivel1.dialogue"), "pregunta_1")


func _on_boton_reiniciar_pressed():
	get_tree().paused = false # ¡MUY IMPORTANTE despausar el motor primero!
	get_tree().reload_current_scene() # Recarga el mapa desde cero con 100 de vida


func _on_boton_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://escenas/Menu.tscn") # Pon la ruta real de tu menú
