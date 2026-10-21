extends Node2D

# =============================================================
# SPAWNER.GD
# =============================================================
# Se encarga de generar monedas en el mapa de forma automática
# y controlada. Trabaja junto a un nodo Timer en la escena:
# cada vez que el Timer llega a cero, intenta crear una moneda.
# =============================================================

# --- CONFIGURACIÓN DESDE EL EDITOR ---
# @export hace que estas variables aparezcan en el panel Inspector de Godot.
# Así se pueden ajustar sin tocar el código.
@export var moneda_scene : PackedScene   # Arrastra aquí la escena Moneda.tscn desde el FileSystem
@export var limite_monedas : int = 15    # Máximo de monedas que pueden coexistir en el mapa al mismo tiempo

# --- VARIABLES DE CONTROL ---
# Referencia al nodo Area2D que creaste como hijo para revisar el mapa
@onready var detector = $Detector
# Contador interno para saber cuántas monedas hay activas actualmente
var monedas_en_mapa : int = 0

# --- LÓGICA DEL TEMPORIZADOR ---
# Esta función se conecta a la señal 'timeout' del nodo Timer desde el editor.
# Se ejecuta automáticamente cada vez que el Timer llega a cero.
func _on_timer_timeout():
	# REGLA NUEVA: Si el jugador ya llegó al límite de monedas, frenamos el spawner
	if Global.monedas_actuales >= Global.meta_monedas:
		return # Detiene la función y no genera nada más
		
	# REGLA: Solo creamos una moneda si no hemos alcanzado el límite máximo permitido
	if monedas_en_mapa < limite_monedas:
		generar_moneda()

# --- CREACIÓN DE MONEDAS ---
func generar_moneda():
	# 1. instantiate() crea una copia "viva" de la escena PackedScene en memoria.
	var nueva_moneda = moneda_scene.instantiate()
	
	# --- VALIDACIÓN ANTICOLISIÓN REFORZADA ---
	var posicion_valida = false
	var intentos = 0
	var offset = Vector2.ZERO
	var posicion_intento = Vector2.ZERO
	
	# Traemos la referencia de la capa de montañas para revisar sus celdas directamente
	# Nota: Asegúrate de que la ruta hacia tu capa "Montañas" sea la correcta
	var capa_montanas = $"../TileMapLayers/Montaña"
	
	while not posicion_valida and intentos < 10:
		intentos += 1
		
		# 2. Calculamos la posición aleatoria tentativa cerca del jugador
		offset = Vector2(randf_range(-300, 300), randf_range(-300, 300))
		posicion_intento = $"../Jugador".position + offset
		
		if capa_montanas:
			# Convertimos la posición global en píxeles a coordenadas de celda (ej: columna 5, fila 3)
			var coordenada_celda = capa_montanas.local_to_map(posicion_intento)
			
			# Le preguntamos al TileMapLayer si hay un dibujo/física en esa celda exacta
			var datos_celda = capa_montanas.get_cell_tile_data(coordenada_celda)
			
			# Si datos_celda es null, significa que la celda está completamente VACÍA (no hay montaña)
			if datos_celda == null:
				posicion_valida = true
		else:
			# Si por alguna razón no encuentra la capa, acepta la posición para no romper el juego
			posicion_valida = true
	
	# 3. Posicionamos la nueva moneda de forma segura en el lugar libre encontrado
	nueva_moneda.position = $"../Jugador".position + offset
	
	# 4. SEÑALES POR CÓDIGO: Conectamos la señal de recolección
	nueva_moneda.tree_exited.connect(_on_moneda_recogida)
	
	# 5. Añadimos la moneda como hija
	add_child(nueva_moneda)
	
	# 6. Sumamos 1 al contador
	monedas_en_mapa += 1

# --- CONTROL DE CONTEO ---
# Esta función se activa automáticamente gracias a la señal conectada en el paso 4
func _on_moneda_recogida():
	# Como una moneda fue eliminada del mapa, restamos 1 para que el spawner pueda generar una nueva
	monedas_en_mapa -= 1
