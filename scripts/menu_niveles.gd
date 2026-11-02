extends Control

var cambiando_escena: bool = false

@onready var cuadricula = $CuadriculaNiveles
@onready var boton_volver = $BotonVolver

# Nodos del Panel Derecho
@onready var numero_nivel = $PanelDetalle/NumeroNivel
@onready var nombre_nivel = $PanelDetalle/NombreNivel
@onready var preview_nivel = $PanelDetalle/PreviewNivel
@onready var objetivos_nivel = $PanelDetalle/ObjetivosNivel
@onready var boton_jugar = $PanelDetalle/BotonJugar

# Nodos de Audio
@onready var sonido_hover = $SonidoHover
@onready var sonido_click = $SonidoClick

# Ruta exacta ajustada a las mayúsculas del proyecto: Assets/UI/Menu Niveles/
const RUTA_ICONO_OBJETIVO = "res://Assets/UI/Menu Niveles/simbolo_objetivo.png"

var boton_seleccionado: Control = null

# Diccionario con la información de los niveles
var datos_niveles = {
	"BotonNivel1": {
		"numero": "Nivel 1",
		"subtitulo": "Comienza la aventura",
		"imagen": preload("res://Assets/UI/Menu Niveles/imagen nivel 1 detalles.png"),
		"objetivos": [
			"Explora el bosque",
			"Ayuda a la aldea"
		],
		"escena": "res://escenas/Mundo.tscn",
		"bloqueado": false
	},
	"BotonNivel2": {
		"numero": "Nivel 2",
		"subtitulo": "La ciudad en llamas",
		"imagen": preload("res://Assets/UI/Menu Niveles/imagen nivel 2 detalles.png"),
		"objetivos": [
			"Sobrevive a la emboscada",
			"Rescata a los aldeanos",
			"Derrota al líder bestia"
		],
		"escena": "res://escenas/Mundo.tscn",
		"bloqueado": true
	}
}

func _ready():
	# Generar datos de "Próximamente" para los niveles 3 al 8
	for i in range(3, 9):
		var nombre_btn = "BotonNivel" + str(i)
		if not datos_niveles.has(nombre_btn):
			datos_niveles[nombre_btn] = {
				"numero": "Nivel " + str(i),
				"subtitulo": "Próximamente",
				"imagen": preload("res://Assets/UI/Menu Niveles/imagen nivel proximamente detalles.png"),
				"objetivos": ["Próximamente"],
				"escena": "",
				"bloqueado": true
			}

	# Conectar Botón Volver
	if boton_volver:
		_conectar_efectos_boton(boton_volver)
		if not boton_volver.pressed.is_connected(_on_boton_volver_pressed):
			boton_volver.pressed.connect(_on_boton_volver_pressed)

	# Conectar Botón Jugar
	if boton_jugar:
		_conectar_efectos_boton(boton_jugar)
		if not boton_jugar.pressed.is_connected(_on_boton_jugar_pressed):
			boton_jugar.pressed.connect(_on_boton_jugar_pressed)

	# Conectar Tarjetas de la Cuadrícula
	for boton in cuadricula.get_children():
		if boton is TextureButton:
			_conectar_efectos_boton(boton)
			if not boton.pressed.is_connected(_on_tarjeta_nivel_pressed):
				boton.pressed.connect(_on_tarjeta_nivel_pressed.bind(boton))

	# Seleccionar Nivel 1 por defecto al abrir el menú
	var primer_boton = cuadricula.get_node_or_null("BotonNivel1")
	if primer_boton:
		_on_tarjeta_nivel_pressed(primer_boton)


# Conecta las señales de entrada/salida del ratón para sonido y neón
func _conectar_efectos_boton(boton: Control):
	if not boton.mouse_entered.is_connected(_on_boton_mouse_entered):
		boton.mouse_entered.connect(_on_boton_mouse_entered.bind(boton))
	if not boton.mouse_exited.is_connected(_on_boton_mouse_exited):
		boton.mouse_exited.connect(_on_boton_mouse_exited.bind(boton))


func _on_boton_mouse_entered(boton: Control):
	if sonido_hover and not sonido_hover.playing:
		sonido_hover.play()
		
	if boton != boton_seleccionado and boton.has_node("BordeSeleccion"):
		boton.get_node("BordeSeleccion").visible = true


func _on_boton_mouse_exited(boton: Control):
	if boton != boton_seleccionado and boton.has_node("BordeSeleccion"):
		boton.get_node("BordeSeleccion").visible = false


func _on_tarjeta_nivel_pressed(boton: Control):
	if sonido_click:
		sonido_click.play()
		
	# Desactivar borde de la tarjeta previa
	if boton_seleccionado and boton_seleccionado.has_node("BordeSeleccion"):
		boton_seleccionado.get_node("BordeSeleccion").visible = false
	
	# Activar borde de la nueva tarjeta
	boton_seleccionado = boton
	if boton_seleccionado.has_node("BordeSeleccion"):
		boton_seleccionado.get_node("BordeSeleccion").visible = true
	
	actualizar_panel_detalle(boton.name)


func actualizar_panel_detalle(nombre_boton: String):
	if datos_niveles.has(nombre_boton):
		var info = datos_niveles[nombre_boton]
		
		numero_nivel.text = info["numero"]
		nombre_nivel.text = info["subtitulo"]
		preview_nivel.texture = info["imagen"]
		
		# Generar texto BBCode con la imagen del diamantecito antes de cada punto
		var texto_bbcode = ""
		for obj in info["objetivos"]:
			texto_bbcode += "[img=14]" + RUTA_ICONO_OBJETIVO + "[/img]  " + obj + "\n"
		
		objetivos_nivel.text = texto_bbcode
		
		# Estado visual del botón JUGAR si el nivel está bloqueado
		if info["bloqueado"]:
			boton_jugar.disabled = true
			boton_jugar.modulate = Color(0.4, 0.4, 0.4, 0.8)
		else:
			boton_jugar.disabled = false
			boton_jugar.modulate = Color(1, 1, 1, 1)


func _on_boton_jugar_pressed():
	if cambiando_escena:
		return
	if sonido_click:
		sonido_click.play()
		
	if boton_seleccionado and datos_niveles.has(boton_seleccionado.name):
		var info = datos_niveles[boton_seleccionado.name]
		if not info["bloqueado"] and info["escena"] != "":
			cambiando_escena = true
			var numero_elegido = str(boton_seleccionado.name).trim_prefix("BotonNivel").to_int()
			await get_tree().create_timer(0.12).timeout
			Global.preparar_nivel(numero_elegido)
			get_tree().change_scene_to_file(info["escena"])


func _on_boton_volver_pressed():
	if cambiando_escena:
		return
	cambiando_escena = true
	if sonido_click:
		sonido_click.play()
	await get_tree().create_timer(0.12).timeout
	get_tree().change_scene_to_file("res://escenas/Menu.tscn")
