extends Control

# --- REFERENCIAS A LOS SONIDOS DEL MENÚ PRINCIPAL ---
@onready var sonido_hover = $"../SonidoHover"
@onready var sonido_click = $"../SonidoClick"

# --- REFERENCIAS AL CONTENIDO CENTRAL (LAS PÁGINAS) ---
@onready var pagina_movimiento = $Fondo/PaginaMovimiento
@onready var pagina_combate = $Fondo/PaginaCombate
@onready var pagina_objetivo = $Fondo/PaginaObjetivo

# --- REFERENCIAS A LOS BORDES NEÓN (DENTRO DE TUS "VENTANAS" DE ARRIBA) ---
@onready var borde_movimiento = $Fondo/VentanasArriba/VentanaMovimiento/BordeSeleccion
@onready var borde_combate = $Fondo/VentanasArriba/VentanaCombate/BordeSeleccion
@onready var borde_objetivo = $Fondo/VentanasArriba/VentanaObjetivo/BordeSeleccion

# --- REFERENCIAS A INTERFAZ DE NAVEGACIÓN ---
@onready var texto_pagina = $Fondo/TextoPagina
@onready var boton_volver = $Fondo/BotonVolver
@onready var boton_siguiente = $Fondo/BotonSiguiente
@onready var boton_cerrar = $Fondo/BotonCerrar

var pagina_actual = 1
var total_paginas = 3

func _ready():
	mostrar_pagina(1)
	
	# Activar el efecto del contorno neón y sonido hover
	var botones_nav = [boton_volver, boton_siguiente, boton_cerrar]
	for boton in botones_nav:
		if boton != null:
			boton.mouse_entered.connect(_al_entrar_raton.bind(boton))
			boton.mouse_exited.connect(_al_salir_raton.bind(boton))


# --- FUNCIONES PARA EL EFECTO NEÓN Y SONIDO HOVER ---
func _al_entrar_raton(boton):
	if sonido_hover and not sonido_hover.playing:
		sonido_hover.play()
		
	if boton.has_node("BordeSeleccion"):
		boton.get_node("BordeSeleccion").visible = true

func _al_salir_raton(boton):
	if boton.has_node("BordeSeleccion"):
		boton.get_node("BordeSeleccion").visible = false


# --- FUNCIÓN PRINCIPAL DE NAVEGACIÓN ---
func mostrar_pagina(numero):
	pagina_actual = numero
	
	if texto_pagina:
		texto_pagina.text = str(pagina_actual) + " / " + str(total_paginas)
	
	if boton_volver:
		boton_volver.visible = (pagina_actual > 1) 
	
	# --- AQUÍ ESTÁ LA MAGIA DEL BOTÓN ENTENDIDO ---
	if boton_siguiente:
		if boton_siguiente.has_node("Label"):
			if pagina_actual == total_paginas:
				boton_siguiente.get_node("Label").text = "Entendido"
			else:
				boton_siguiente.get_node("Label").text = "Siguiente"
	# ---------------------------------------------
	
	if pagina_movimiento: pagina_movimiento.visible = false
	if pagina_combate: pagina_combate.visible = false
	if pagina_objetivo: pagina_objetivo.visible = false
	
	if borde_movimiento: borde_movimiento.visible = false
	if borde_combate: borde_combate.visible = false
	if borde_objetivo: borde_objetivo.visible = false
	
	match pagina_actual:
		1:
			if pagina_movimiento: pagina_movimiento.visible = true
			if borde_movimiento: borde_movimiento.visible = true
		2:
			if pagina_combate: pagina_combate.visible = true
			if borde_combate: borde_combate.visible = true
		3:
			if pagina_objetivo: pagina_objetivo.visible = true
			if borde_objetivo: borde_objetivo.visible = true


# ==========================================
# CONEXIONES DE BOTONES (CLICS Y SONIDO)
# ==========================================

func _on_boton_volver_pressed():
	if sonido_click: sonido_click.play()
	if pagina_actual > 1:
		mostrar_pagina(pagina_actual - 1)

func _on_boton_siguiente_pressed():
	if sonido_click: sonido_click.play()
	
	# --- AQUÍ DECIDIMOS SI AVANZAR O CERRAR ---
	if pagina_actual < total_paginas:
		mostrar_pagina(pagina_actual + 1)
	else:
		self.visible = false # Cierra el menú al presionar "Entendido"
	# ----------------------------------------

func _on_boton_cerrar_pressed():
	if sonido_click: sonido_click.play()
	self.visible = false
