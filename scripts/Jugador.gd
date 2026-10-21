extends CharacterBody2D

# =============================================================
# JUGADOR.GD
# =============================================================
# Controla el movimiento, las animaciones, el sistema de vida 
# y los estados de ataque del personaje.
# =============================================================

# --- CONFIGURACIÓN DE MOVIMIENTO ---
const SPEED = 150.0  # Velocidad del jugador en píxeles por segundo

# --- SISTEMA DE VIDA ---
var vida_maxima: float = 100.0
var vida_actual: float = 100.0

@onready var pantalla_muerte = $"../UI/Interfaz/PantallaMuerte"

# Referencia a la barra en la interfaz HD
@onready var barra_vida = $"../UI/Interfaz/BarraVida"
@onready var texto_vida = $"../UI/Interfaz/BarraVida/TextoVida"

# --- CONFIGURACIÓN DE LA CÁMARA ---
@onready var camara = $Camera2D
var zoom_normal: float = 1.0
var zoom_escalera: float = 0.7
var zoom_objetivo: float = 1.0

# --- ESTADOS INTERNOS DEL PERSONAJE ---
var ultima_direccion = "abajo"  # Guarda hacia dónde miraba el jugador por última vez
var espada_equipada = false      # true = la espada está activa; false = guardada
var animando_espada = false     # true = reproduciendo animación de sacar/guardar
var atacando = false            # true = bloquea movimiento durante el espadazo


# =============================================================
# 1. FUNCIONES PRINCIPALES DEL MOTOR (CICLO DE VIDA)
# =============================================================

func _ready():
	if barra_vida:
		barra_vida.max_value = vida_maxima
		barra_vida.value = vida_actual
	
	# Usamos int() para borrar los decimales antes de pasarlo a texto
	if texto_vida:
		texto_vida.text = str(int(vida_actual)) + " / " + str(int(vida_maxima))


func _physics_process(delta):
	# 1. Capturamos los vectores de movimiento
	var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# --- CONTROL DE CAPAS VISUALES (Z-INDEX) ---
	var suelo_actual = obtener_datos_suelo(Vector2.ZERO)
	if suelo_actual == "stair":
		z_index = 2 
	else:
		z_index = 1 
	
	# 2. Aplicamos velocidad si no se encuentra realizando acciones
	if not animando_espada and not atacando:
		velocity = direction * SPEED
		actualizar_animacion_y_direccion(direction)
	else:
		velocity = Vector2.ZERO
		
	move_and_slide()
	
	# 3. Control de entradas del teclado e inventario
	if Input.is_action_just_pressed("espada") and not animando_espada and not atacando:
		if not espada_equipada: 
			sacar_espada()
		else: 
			guardar_espada()
			
	if Input.is_action_just_pressed("atacar") and not atacando and not animando_espada:
		if espada_equipada:
			atacar()

	# 4. Transición suave del zoom de la cámara
	if camara:
		var zoom_actual = lerp(camara.zoom.x, zoom_objetivo, 3.0 * delta)
		camara.zoom = Vector2(zoom_actual, zoom_actual)


func _input(event):
	# PRUEBA DE DAÑO MANUAL: Al presionar la B una sola vez, descuenta vida limpiamente
	if event is InputEventKey and event.pressed and event.keycode == KEY_B:
		recibir_daño(10)


# =============================================================
# 2. MÁQUINA DE ESTADOS Y ANIMACIONES
# =============================================================

func actualizar_animacion_y_direccion(direction):
	# Guardamos la última dirección según el eje predominante
	if direction.x > 0: ultima_direccion = "derecha"
	elif direction.x < 0: ultima_direccion = "izquierda"
	elif direction.y < 0: ultima_direccion = "arriba"
	elif direction.y > 0: ultima_direccion = "abajo"

	var anim_nombre = ""
	
	# CONDICIÓN: Si el personaje se está moviendo activamente
	if direction != Vector2.ZERO:
		if espada_equipada:
			# Truco flip_h para animaciones que no tienen lado izquierdo nativo
			if ultima_direccion == "izquierda":
				anim_nombre = "c_espada_derecha"
				$AnimatedSprite2D.flip_h = true
			else:
				anim_nombre = "c_espada_" + ultima_direccion
				$AnimatedSprite2D.flip_h = false
		else:
			# Caminar normal sin espada
			if ultima_direccion == "izquierda":
				anim_nombre = "caminar_derecha"
				$AnimatedSprite2D.flip_h = true
			else:
				anim_nombre = "caminar_" + ultima_direccion
				$AnimatedSprite2D.flip_h = false
		$AnimatedSprite2D.play(anim_nombre)
	else:
		# CONDICIÓN: Si el personaje está completamente quieto
		if espada_equipada:
			if ultima_direccion == "izquierda":
				anim_nombre = "e_quieto_derecha"
				$AnimatedSprite2D.flip_h = true
			else:
				anim_nombre = "e_quieto_" + ultima_direccion
				$AnimatedSprite2D.flip_h = false
		else:
			if ultima_direccion == "izquierda":
				anim_nombre = "quieto_derecha"
				$AnimatedSprite2D.flip_h = true
			else:
				anim_nombre = "quieto_" + ultima_direccion
				$AnimatedSprite2D.flip_h = false
		
		$AnimatedSprite2D.play(anim_nombre)


# =============================================================
# 3. ACCIONES DE COMBATE Y HABILIDADES
# =============================================================

func sacar_espada():
	animando_espada = true
	var anim_name = "s_espada_" + ultima_direccion
	
	if ultima_direccion == "izquierda":
		anim_name = "s_espada_derecha"
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
	
	$AnimatedSprite2D.play(anim_name)
	await $AnimatedSprite2D.animation_finished
	espada_equipada = true
	animando_espada = false
	actualizar_animacion_y_direccion(Vector2.ZERO) 
	

func guardar_espada():
	animando_espada = true
	var anim_name = "s_espada_" + ultima_direccion
	
	if ultima_direccion == "izquierda":
		anim_name = "s_espada_derecha"
		$AnimatedSprite2D.flip_h = true
	else:
		$AnimatedSprite2D.flip_h = false
	
	$AnimatedSprite2D.play_backwards(anim_name)
	await $AnimatedSprite2D.animation_finished
	espada_equipada = false
	animando_espada = false
	actualizar_animacion_y_direccion(Vector2.ZERO)
	

func atacar():
	atacando = true
	
	var anim_name = "atacar_" + ultima_direccion
	
	# Apagamos el flip_h porque cuentas con sprites nativos para izquierda/derecha
	$AnimatedSprite2D.flip_h = false
	
	# Reproduce los 3 frames de ataque configurados en el editor
	$AnimatedSprite2D.play(anim_name)
	
	# Espera el término del golpe antes de regresar el control al jugador
	await $AnimatedSprite2D.animation_finished
	
	atacando = false
	actualizar_animacion_y_direccion(Vector2.ZERO)


# =============================================================
# 4. SISTEMAS DE LÓGICA MUNDO Y SALUD
# =============================================================

func recibir_daño(cantidad):
	vida_actual -= cantidad
	vida_actual = clamp(vida_actual, 0.0, vida_maxima) 
	
	if barra_vida:
		barra_vida.value = vida_actual
		
	if texto_vida:
		texto_vida.text = str(int(vida_actual)) + " / " + str(int(vida_maxima))
		
	# =============================================================
	# LÓGICA DE MUERTE CORREGIDA
	# =============================================================
	if vida_actual <= 0:
		if pantalla_muerte:
			pantalla_muerte.visible = true # Mostramos el menú de Game Over
			get_tree().paused = true       # Pausamos el movimiento de todo el juego


func obtener_datos_suelo(offset_anticipacion: Vector2) -> String:
	var tilemap = $"../TileMapLayers/Escalera" 
	if not tilemap:
		return ""
		
	var posicion_revision = global_position + Vector2(0, 10) + offset_anticipacion
	var celda = tilemap.local_to_map(posicion_revision)
	var datos_celda = tilemap.get_cell_tile_data(celda)
	
	if datos_celda:
		return datos_celda.get_custom_data("stair")
	return ""
