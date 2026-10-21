extends Area2D

func _on_body_entered(body):
	if body.name == "Jugador":
		print("ENTRÓ")
		body.zoom_objetivo = body.zoom_escalera

func _on_body_exited(body):
	if body.name == "Jugador":
		print("SALIÓ")
		body.zoom_objetivo = body.zoom_normal
