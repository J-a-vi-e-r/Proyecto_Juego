extends Area2D

# =============================================================
# MONEDA.GD
# =============================================================
# Cada moneda en el mapa tiene este script. Usa Area2D, que es
# el nodo de Godot para detectar superposiciones sin aplicar
# físicas reales (no empuja ni rebota, solo detecta contacto).
# La señal 'body_entered' se conecta desde el editor.
# =============================================================

# --- REFERENCIA AL AUDIO ---
# Vinculamos el nodo de sonido que agregaremos en la escena
@onready var sonido_moneda = $AudioStreamPlayer2D

# --- ACTIVACIÓN DE ANIMACIÓN ---
# Esta función se ejecuta automáticamente cuando la moneda aparece en el mapa
func _ready():
	# Le dice al AnimatedSprite2D que empiece a reproducir la animación "Moneda"
	$AnimatedSprite2D.play("Moneda")

# --- DETECCIÓN DE CONTACTO ---
# Esta función se activa automáticamente cuando otro cuerpo físico entra al área de la moneda
func _on_body_entered(body):
	# Verificamos mediante su nombre (el que se coloco en el nodo de characterbody2d)
	# que el objeto que nos tocó sea efectivamente el Jugador.
	# Usar body.name es simple y funciona bien en proyectos pequeños.
	if body.name == "Jugador":
		
		# =============================================================
		# NUEVO: CONTROL DE LÍMITE (REGLA 1 y 2)
		# =============================================================
		# Si el jugador ya tiene el máximo de monedas (o más) y vuelve a tocar una moneda:
		if Global.monedas_actuales >= Global.meta_monedas:
			# No le sumamos monedas ni la destruimos.
			# En su lugar, volvemos a abrir el diálogo por si ahora sí quiere responder.
			Global.fallos = 0
			DialogueManager.show_example_dialogue_balloon(load("res://Dialogos/Nivel1.dialogue"), "inicio_trivia")
			return # Detiene por completo la ejecución de esta función aquí mismo
		# =============================================================
		
		# 1. Sumamos una moneda directamente al contador persistente en el Singleton Global
		Global.monedas_actuales += 1
		# Imprimimos en la consola de Godot para facilitar el debugging durante el desarrollo
		print("Monedas actuales: ", Global.monedas_actuales)
		
		# =============================================================
		# NUEVO: PREPARACIÓN DEL SONIDO
		# =============================================================
		# Desactivamos el monitoreo para que el jugador no pueda tocarla dos veces mientras suena
		set_deferred("monitoring", false)
		# Escondemos los elementos visuales (la animación y sombras si tuviera)
		$AnimatedSprite2D.visible = false
		# Reproducimos el efecto de sonido
		sonido_moneda.play()
		# =============================================================
		
		# 2. VERIFICACIÓN: ¿El jugador ya recolectó las monedas suficientes para avanzar?
		if Global.monedas_actuales >= Global.meta_monedas:
			Global.fallos = 0
			DialogueManager.show_example_dialogue_balloon(load("res://Dialogos/Nivel1.dialogue"), "inicio_trivia")
		
		# =============================================================
		# NUEVO: ESPERA DEL AUDIO
		# =============================================================
		# Pausamos la eliminación de este objeto hasta que el audio termine de reproducirse
		await sonido_moneda.finished
		# =============================================================
		
		# 3. Marcamos esta moneda para que Godot la elimine del árbol de escena de forma segura.
		# queue_free no la borra instantáneamente, sino al final del frame (igual de seguro que call_deferred).
		queue_free()
