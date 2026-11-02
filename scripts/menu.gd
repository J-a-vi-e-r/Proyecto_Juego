extends Control

var cambiando_escena: bool = false

@onready var contenedor_botones = $ContenedorBotones
# 1. Agregamos la referencia al panel (ajusta el nombre si en tu árbol se llama distinto)
@onready var panel_como_jugar = $PanelComoJugar 

@onready var sonido_hover = $SonidoHover
@onready var sonido_click = $SonidoClick

func _ready():
	# 2. Nos aseguramos de que el menú de Cómo Jugar empiece apagado al iniciar el juego
	if panel_como_jugar:
		panel_como_jugar.visible = false

	# Conectamos la entrada y salida del ratón para encender el borde neón
	for boton in contenedor_botones.get_children():
		if boton is TextureButton or boton is Button:
			var cb_enter = Callable(self, "_on_boton_mouse_entered").bind(boton)
			var cb_exit = Callable(self, "_on_boton_mouse_exited").bind(boton)
			
			if not boton.mouse_entered.is_connected(cb_enter):
				boton.mouse_entered.connect(cb_enter)
			if not boton.mouse_exited.is_connected(cb_exit):
				boton.mouse_exited.connect(cb_exit)


func _on_boton_mouse_entered(boton: Control):
	if sonido_hover and not sonido_hover.playing:
		sonido_hover.play()
	if boton.has_node("BordeSeleccion"):
		boton.get_node("BordeSeleccion").visible = true


func _on_boton_mouse_exited(boton: Control):
	if boton.has_node("BordeSeleccion"):
		boton.get_node("BordeSeleccion").visible = false


# Las funciones de clic quedan como las conectaste desde el editor
func _on_boton_jugar_pressed():
	if cambiando_escena:
		return
	cambiando_escena = true
	if sonido_click:
		sonido_click.play()
	await get_tree().create_timer(0.12).timeout
	get_tree().change_scene_to_file("res://escenas/MenuNiveles.tscn")


func _on_boton_como_jugar_pressed():
	if sonido_click:
		sonido_click.play()
	# 3. Encendemos el panel al hacer clic
	if panel_como_jugar:
		panel_como_jugar.visible = true


func _on_boton_opciones_pressed():
	if sonido_click:
		sonido_click.play()


func _on_boton_salir_pressed():
	if cambiando_escena:
		return
	cambiando_escena = true
	if sonido_click:
		sonido_click.play()
	await get_tree().create_timer(0.12).timeout
	get_tree().quit()
