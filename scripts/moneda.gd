extends Area2D

var recogida: bool = false

@onready var sonido_moneda = $AudioStreamPlayer2D

func _ready():
	$AnimatedSprite2D.play("Moneda")

func _on_body_entered(body):
	# ¡Ah! Aquí dice que tu héroe se llama "Jugador", no "Player".
	if body.name == "Jugador" and not recogida:
		recogida = true
		
		# Ya no verificamos si tiene el límite para abrir diálogos,
		# solo queremos que sume la moneda si tiene menos de la meta.
		if Global.monedas_actuales < Global.meta_monedas:
			Global.monedas_actuales += 1
			print("Monedas actuales: ", Global.monedas_actuales)
			
			# Efecto de agarrar la moneda
			set_deferred("monitoring", false)
			$AnimatedSprite2D.visible = false
			sonido_moneda.play()
			
			# Esperar a que termine el sonido y borrarla
			sonido_moneda.finished.connect(queue_free, CONNECT_ONE_SHOT)
		else:
			# Si ya tiene el límite, por ahora solo desaparecemos la moneda extra
			# o podrías simplemente hacer un 'return' si quieres que la moneda no se pueda agarrar
			queue_free()
