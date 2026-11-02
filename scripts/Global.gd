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
var trivia_aprobada: bool = false
var globo_dialogo: Node = null
var texto_repaso = ""     # Guardará la lista de respuestas correctas para el final

# --- FUNCIONES DE UTILIDAD ---
# Reinicia el contador de monedas a cero. Se llama al empezar un nivel limpio.
func reset_monedas_nivel():
	monedas_actuales = 0
	fallos = 0
	texto_repaso = ""
	trivia_aprobada = false


func preparar_nivel(numero: int):
	nivel_actual = numero
	meta_monedas = numero * 10
	reset_monedas_nivel()


func hay_dialogo_activo() -> bool:
	return is_instance_valid(globo_dialogo)


func mostrar_dialogo(titulo: String) -> Node:
	if hay_dialogo_activo():
		return null
	globo_dialogo = DialogueManager.show_dialogue_balloon(load("res://Dialogos/Nivel1.dialogue"), titulo)
	bloquear_movimiento_dialogo()
	return globo_dialogo


func registrar_dialogo(globo: Node):
	globo_dialogo = globo
	bloquear_movimiento_dialogo()


func finalizar_dialogo(globo: Node):
	if globo_dialogo != globo:
		return
	globo_dialogo = null
	descongelar_juego()


func _buscar_nodo_actual(nombre: String) -> Node:
	if not is_inside_tree() or get_tree().current_scene == null:
		return null
	var escena = get_tree().current_scene
	if escena.name == nombre:
		return escena
	return escena.find_child(nombre)

# Registra de forma silenciosa la pregunta fallada y su respuesta correcta
func registrar_fallo(pregunta: String, respuesta_correcta: String):
	fallos += 1
	texto_repaso += "• " + pregunta + "\n  La respuesta correcta era: " + respuesta_correcta + "\n\n"

# Evalúa lo que pasa al terminar el diálogo
func evaluar_resultados_trivia():
	trivia_aprobada = fallos < 2
	if not trivia_aprobada:
		fallos = 0
		texto_repaso = ""
		mostrar_boton_trivia()
	else:
		fallos = 0
		nivel_actual += 1
		meta_monedas += 10
		monedas_actuales = 0
		limpiar_y_rearmar_mapa()
		# El mismo diálogo muestra el resultado y conserva el repaso.

# =============================================================
# CONTROL DE MOVIMIENTO PARA LA TRIVIA
# =============================================================
func congelar_juego():
	fallos = 0
	texto_repaso = ""
	bloquear_movimiento_dialogo()


func bloquear_movimiento_dialogo():
	var jugador = _buscar_nodo_actual("Jugador")
	if jugador:
		jugador.velocity = Vector2.ZERO
		# No interrumpir un golpe o una animación que espera animation_finished.
		if jugador.has_method("actualizar_animacion_y_direccion") and not jugador.atacando and not jugador.animando_espada:
			jugador.actualizar_animacion_y_direccion(Vector2.ZERO)
		jugador.set_physics_process(false)


func descongelar_juego():
	if hay_dialogo_activo():
		return
	var jugador = _buscar_nodo_actual("Jugador")
	if jugador and jugador.vida_actual > 0:
		jugador.set_physics_process(true)

# =============================================================
# CONTROL DEL BOTÓN FLOTANTE DE LA TRIVIA
# =============================================================
# Muestra el botón en pantalla para retomar la trivia cuando el jugador quiera.
func mostrar_boton_trivia():
	var boton = _buscar_nodo_actual("BotonTrivia")
	if boton:
		boton.visible = true

# Oculta el botón una vez que el jugador ya decide responder.
func ocultar_boton_trivia():
	var boton = _buscar_nodo_actual("BotonTrivia")
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
	var spawner = _buscar_nodo_actual("Spawner")
	if spawner:
		spawner.monedas_en_mapa = 0 # Le decimos que el mapa está vacío
		# Si tu spawner tiene un nodo Timer interno, lo forzamos a reiniciarse
		var timer = spawner.get_node_or_null("Timer")
		if timer:
			timer.start() # Arranca el reloj de nuevo para que spawnee rápido
