extends Node

# =============================================================
# GLOBAL.GD — Autoload / Singleton
# =============================================================
# Este script es un SINGLETON: Godot lo carga una sola vez y lo
# mantiene vivo durante toda la sesión del juego, sin importar
# cuántas veces se cambie de escena. Eso permite que cualquier
# otro script pueda leer o modificar estas variables escribiendo
# simplemente:  Global.nombre_variable
#
# --- CÓMO CREAR Y REGISTRAR ESTE SCRIPT (paso a paso) ---
#
#  PASO 1 — Crear el archivo:
#   · En el panel FileSystem (abajo a la izquierda), clic derecho
#     en la carpeta raíz del proyecto (res://) 
#     o si creaste una carpeta para todos los scripts hazlo en esa > Crear Nuevo > Script
#   · Nómbralo Global.gd y asegúrate de que extiende Node
#  
#  · Escribe aquí las variables y funciones que necesites
#
#  PASO 2 — Registrarlo como Autoload:
#   · En la barra superior: Proyecto > Configuración del Proyecto
#   · Ve a la pestaña "Globales"
#   · En el campo "Ruta" haz clic en el ícono de carpeta y busca
#     el Global.gd que acabas de crear en el FileSystem o la carpeta de scripts
#   · En el campo "Nombre" escribe exactamente:  Global
#     (ese nombre es el que usarás en el código: Global.monedas_actuales)
#   · Haz clic en "Agregar" — si no haces clic no se guarda
#   · Cierra la ventana
#
#  ✔ Si lo hiciste bien, "Global" aparece en la lista de Autoloads.
#
#  ✘ Error común: escribir el nombre con minúscula ("global") hace que
#    Global.variable no funcione y Godot dé error de identificador.
# =============================================================

# --- VARIABLES GLOBALES DEL JUEGO ---
var monedas_actuales = 0  # Monedas que el jugador lleva recolectadas en el nivel actual
var meta_monedas = 10     # Monedas necesarias para desbloquear la trivia y pasar de nivel
var nivel_actual = 1      # El nivel o fase en la que se encuentra el jugador

# --- VARIABLES PARA LA TRIVIA NUEVA ---
var fallos = 0
var texto_repaso = ""     # Guardará la lista de respuestas correctas para el final

# --- FUNCIONES DE UTILIDAD ---
# Reinicia el contador de monedas a cero. Se llama al empezar un nivel limpio.
func reset_monedas_nivel():
	monedas_actuales = 0

# Registra de forma silenciosa la pregunta fallada y su respuesta correcta
func registrar_fallo(pregunta: String, respuesta_correcta: String):
	fallos += 1
	texto_repaso += "• " + pregunta + "\n  La respuesta correcta era: " + respuesta_correcta + "\n\n"

# Evalúa lo que pasa al terminar el diálogo
func evaluar_resultados_trivia():
	# CONDICIÓN DE DERROTA: 2 o más fallos
	if fallos >= 2:
		fallos = 0
		texto_repaso = ""
		mostrar_boton_trivia()
		DialogueManager.show_example_dialogue_balloon(load("res://Dialogos/Nivel1.dialogue"), "pantalla_derrota")
		
	# CONDICIÓN DE VICTORIA: menos de 2 fallos (0 o 1 error)
	else:
		var repaso_final = texto_repaso
		
		fallos = 0
		texto_repaso = ""
		
		# Progreso del jugador
		nivel_actual += 1
		meta_monedas += 10
		monedas_actuales = 0
		
		# --- NUEVO: Limpiamos los restos del nivel viejo y despertamos al spawner ---
		limpiar_y_rearmar_mapa()
		
		# Si tuvo 1 error, le mostramos la pantalla de victoria con el repaso incluido
		if repaso_final != "":
			Global.texto_repaso = repaso_final
			DialogueManager.show_example_dialogue_balloon(load("res://Dialogos/Nivel1.dialogue"), "pantalla_victoria_repaso")
		else:
			DialogueManager.show_example_dialogue_balloon(load("res://Dialogos/Nivel1.dialogue"), "pantalla_victoria_perfecta")

# =============================================================
# CONTROL DE MOVIMIENTO PARA LA TRIVIA
# =============================================================
func congelar_juego():
	# find_child busca en todo el árbol de la escena actual al nodo llamado "Jugador"
	var jugador = get_tree().current_scene.find_child("Jugador")
	if jugador:
		# 1. Frenamos el vector de velocidad a cero absoluto para detener el movimiento físico
		jugador.velocity = Vector2.ZERO
		
		# 2. Llamamos a su propia función para forzar el estado quieto (idle) 
		# respetando perfectamente la última dirección en la que miraba (arriba, abajo, etc.)
		if jugador.has_method("actualizar_animacion_y_direccion"):
			jugador.actualizar_animacion_y_direccion(Vector2.ZERO)
		
		# 3. Bloqueamos el procesamiento de físicas para que ignore las flechas del teclado/mando
		jugador.set_physics_process(false)
	
	# --- SOLUCIÓN AL BUG DE REPASO REPETIDO ---
	# Cada vez que el juego se congela para empezar una trivia (ya sea por moneda o botón),
	# vaciamos por completo el texto de repaso del intento anterior.
	texto_repaso = ""

func descongelar_juego():
	var jugador = get_tree().current_scene.find_child("Jugador")
	if jugador:
		# Volvemos a encender el script del jugador para regresarle el control total
		jugador.set_physics_process(true)

# =============================================================
# CONTROL DEL BOTÓN FLOTANTE DE LA TRIVIA
# =============================================================
# Muestra el botón en pantalla para retomar la trivia cuando el jugador quiera.
func mostrar_boton_trivia():
	var boton = get_tree().current_scene.find_child("BotonTrivia")
	if boton:
		boton.visible = true

# Oculta el botón una vez que el jugador ya decide responder.
func ocultar_boton_trivia():
	var boton = get_tree().current_scene.find_child("BotonTrivia")
	if boton:
		boton.visible = false

# Hace desaparecer temporalmente todas las monedas del mapa.
func ocultar_monedas_mapa():
	# Busca todas las monedas que tengan asignado el grupo "Monedas"
	var monedas = get_tree().get_nodes_in_group("Monedas")
	for moneda in monedas:
		moneda.visible = false
		moneda.set_deferred("monitoring", false) # Desactiva las colisiones

# =============================================================
# REINICIO Y LIMPIEZA DE NIVEL
# =============================================================
func limpiar_y_rearmar_mapa():
	# 1. Buscamos todas las monedas del grupo y las eliminamos de verdad
	var monedas = get_tree().get_nodes_in_group("Monedas")
	for moneda in monedas:
		moneda.queue_free() # Las borramos por completo del juego
		
	# 2. Buscamos el script del Spawner en la escena actual para resetear su conteo
	var spawner = get_tree().current_scene.find_child("Spawner")
	if spawner:
		spawner.monedas_en_mapa = 0 # Le decimos que el mapa está vacío
		# Si tu spawner tiene un nodo Timer interno, lo forzamos a reiniciarse
		var timer = spawner.get_node_or_null("Timer")
		if timer:
			timer.start() # Arranca el reloj de nuevo para que spawnee rápido
