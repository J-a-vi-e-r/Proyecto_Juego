extends Area2D

@onready var icono_pregunta = $Signo
@onready var icono_f = $Tecla
@onready var npc = $NPC

var jugador_cerca = false

func _ready():
	icono_pregunta.visible = true
	icono_f.visible = false
	
	npc.play()
	icono_pregunta.play()
	icono_f.play()

# ¡Revisa que esta línea tenga la flechita o ícono verde al lado!
func _on_body_entered(body):
	if body.name == "Jugador": 
		jugador_cerca = true
		icono_pregunta.visible = false
		icono_f.visible = true

# ¡Revisa que esta línea también tenga el ícono verde al lado!
func _on_body_exited(body):
	if body.name == "Jugador":
		jugador_cerca = false
		icono_pregunta.visible = true
		icono_f.visible = false

func _unhandled_input(event):
	if jugador_cerca and not Global.hay_dialogo_activo() and event.is_action_pressed("interactuar"):
		Global.mostrar_dialogo("inicio_recepcionista")
		get_viewport().set_input_as_handled()
