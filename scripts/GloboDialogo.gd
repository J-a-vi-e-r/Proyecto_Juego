extends CanvasLayer
## Cuadro personalizado del juego. Dialogue Manager sigue gestionando el texto.


## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given title when using balloon as a [Node] in a scene.
@export var start_from_title: String = ""

## If running as a [Node] in a scene then auto start the dialogue.
@export var auto_start: bool = false

## If all other input is blocked as long as dialogue is shown.
@export var will_block_other_input: bool = true

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## A sound player for voice lines (if they exist).
@onready var audio_stream_player: AudioStreamPlayer = %AudioStreamPlayer

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false
var avanzando_linea: bool = false

## Ajustes del retrato en segundos; no modifican los archivos PNG.
@export_range(0.08, 0.4, 0.01) var intervalo_boca: float = 0.16
@export_range(1.5, 6.0, 0.1) var intervalo_parpadeo: float = 3.2
@export_range(0.08, 0.3, 0.01) var duracion_parpadeo: float = 0.12
@export_range(4.0, 24.0, 1.0) var espacio_respuestas: float = 6.0
@export_range(4.0, 24.0, 1.0) var distancia_respuestas: float = 10.0

var tiempo_retrato: float = 0.0
var personaje_retrato: String = ""
var recorte_retrato: Rect2
var fotograma_retrato: int = -1
var textura_retrato: AtlasTexture

@onready var retrato: TextureRect = $Balloon/MarginContainer/PanelContainer/MarginContainer/HBoxContainer/TextureRect/Retrato
@onready var panel_dialogo: PanelContainer = $Balloon/MarginContainer/PanelContainer
@onready var selector_respuesta: TextureRect = %SelectorRespuesta

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var character_label: RichTextLabel = %CharacterLabel

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

## Indicator to show that player can progress dialogue.
@onready var progress: Polygon2D = %Progress


func _ready() -> void:
	mutation_cooldown = Timer.new()
	Global.registrar_dialogo(self)
	balloon.hide()
	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)

	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(false, DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART))
		start()


func _exit_tree() -> void:
	if is_instance_valid(Global):
		Global.finalizar_dialogo(self)


func _process(delta: float) -> void:
	_animar_retrato(delta)
	_actualizar_respuestas()
	if is_instance_valid(dialogue_line):
		progress.visible = not dialogue_label.is_typing and dialogue_line.responses.size() == 0 and not dialogue_line.has_tag("voice")


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	if will_block_other_input:
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = dialogue_label.visible_ratio
		dialogue_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(with_dialogue_resource: DialogueResource = null, title: String = "", extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not title.is_empty():
		start_from_title = title
	dialogue_line = await dialogue_resource.get_next_dialogue_line(start_from_title, temporary_game_states)
	show()


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()

	progress.hide()
	is_waiting_for_input = false
	balloon.focus_mode = Control.FOCUS_ALL
	balloon.grab_focus()

	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = tr(dialogue_line.character, "dialogue")
	_actualizar_retrato(dialogue_line.character)

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses
	responses_menu.size = Vector2(minf(344.0, panel_dialogo.size.x - 20.0), 0.0)

	# Show our balloon
	balloon.show()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		await dialogue_label.finished_typing

	# Wait for next line
	if dialogue_line.has_tag("voice"):
		audio_stream_player.stream = load(dialogue_line.get_tag_value("voice"))
		audio_stream_player.play()
		await audio_stream_player.finished
		next(dialogue_line.next_id)
	elif dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
	elif dialogue_line.time != "":
		var time: float = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()


func _actualizar_retrato(personaje: String) -> void:
	var rutas = {
		"Recepcionista": "res://Assets/NPC, adorno dialogo y enemigo/NPCs/secretaria_portrait.png",
		"Heroe": "res://Assets/NPC, adorno dialogo y enemigo/NPCs/hero_portrait.png",
		"Héroe": "res://Assets/NPC, adorno dialogo y enemigo/NPCs/hero_portrait.png",
		"Aldeano": "res://Assets/NPC, adorno dialogo y enemigo/NPCs/npc_portrait_01.png"
	}
	if not rutas.has(personaje) or personaje == personaje_retrato:
		return
	personaje_retrato = personaje
	# Cada tira tiene cuatro celdas de 100 px. Recortamos el margen transparente
	# de cada personaje para que la imagen llene el hueco de su marco.
	recorte_retrato = Rect2(12, 14, 76, 120)
	if personaje == "Recepcionista":
		recorte_retrato = Rect2(14, 16, 74, 116)
	textura_retrato = AtlasTexture.new()
	textura_retrato.atlas = load(rutas[personaje])
	textura_retrato.region = recorte_retrato
	retrato.texture = textura_retrato
	tiempo_retrato = 0.0
	fotograma_retrato = -1
	_animar_retrato(0.0)


func _animar_retrato(delta: float) -> void:
	if textura_retrato == null:
		return
	tiempo_retrato += delta
	var hablando: bool = dialogue_label.is_typing
	var boca_abierta: bool = hablando and int(tiempo_retrato / intervalo_boca) % 2 == 1
	var parpadeando: bool = fmod(tiempo_retrato, intervalo_parpadeo) >= intervalo_parpadeo - duracion_parpadeo
	var fotograma: int = (2 if boca_abierta else 0) + (1 if parpadeando else 0)
	if fotograma != fotograma_retrato:
		fotograma_retrato = fotograma
		var region: Rect2 = recorte_retrato
		region.position.x += fotograma * 100.0
		textura_retrato.region = region


func _actualizar_respuestas() -> void:
	selector_respuesta.hide()
	if not responses_menu.visible:
		return
	# Compartimos el margen derecho del panel. Las opciones se colocan por encima
	# con un hueco fijo y crecen hacia arriba cuando hay texto de varias líneas.
	var rect_panel: Rect2 = panel_dialogo.get_global_rect()
	var ancho: float = minf(344.0, rect_panel.size.x - 20.0)
	responses_menu.add_theme_constant_override("separation", int(espacio_respuestas))
	if not is_equal_approx(responses_menu.size.x, ancho):
		responses_menu.size.x = ancho
	for opcion in responses_menu.get_menu_items():
		if opcion.get_meta("ancho_medido", -1.0) == ancho:
			continue
		# Button permite envolver el texto, pero su mínimo no siempre incluye todas
		# las líneas. Medimos con la misma fuente para darles el alto necesario.
		var estilo: StyleBox = opcion.get_theme_stylebox("normal")
		var margen_x: float = estilo.get_content_margin(SIDE_LEFT) + estilo.get_content_margin(SIDE_RIGHT)
		var margen_y: float = estilo.get_content_margin(SIDE_TOP) + estilo.get_content_margin(SIDE_BOTTOM)
		var fuente: Font = opcion.get_theme_font("font")
		var alto: float = fuente.get_multiline_string_size(opcion.text, HORIZONTAL_ALIGNMENT_CENTER, ancho - margen_x, opcion.get_theme_font_size("font_size"), -1, TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE).y
		opcion.custom_minimum_size.y = maxf(32.0, ceilf(alto + margen_y))
		opcion.set_meta("ancho_medido", ancho)
	responses_menu.global_position = Vector2(rect_panel.end.x - ancho, rect_panel.position.y - distancia_respuestas - responses_menu.size.y)
	var seleccion: Control = get_viewport().gui_get_focus_owner()
	if seleccion == null or seleccion not in responses_menu.get_menu_items():
		return
	var rect: Rect2 = seleccion.get_global_rect()
	var balanceo: float = sin(tiempo_retrato * TAU) * 1.0
	selector_respuesta.global_position = Vector2(rect.position.x - 13.0 + balanceo, rect.get_center().y - selector_respuesta.size.y * 0.5)
	selector_respuesta.show()


## Go to the next line
func next(next_id: String) -> void:
	if avanzando_linea:
		return
	avanzando_linea = true
	is_waiting_for_input = false
	responses_menu.hide()
	var siguiente_linea = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)
	if not is_inside_tree():
		return
	dialogue_line = siguiente_linea
	avanzando_linea = false


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# See if we need to skip typing of the dialogue
	if dialogue_label.is_typing:
		var mouse_was_clicked: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return

	if not is_waiting_for_input: return
	if dialogue_line.responses.size() > 0: return

	# When there are no response options the balloon itself is the clickable thing
	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)


#endregion


func _on_dialogue_label_spoke(letter: String, letter_index: int, speed: float) -> void:
	# No hacer ruido con espacios ni signos de puntuación.
	if letter.strip_edges().is_empty() or letter in ".,;:!?¡¿…":
		return
# Una de cada dos letras para que el sonido no resulte pesado.
	if letter_index % 2 != 0:
		return
# No cortar un sonido que todavía está terminando.
	if $SonidoLetras.playing:
		return
# Una pequeña variación para que no suene siempre idéntico.
	$SonidoLetras.pitch_scale = randf_range(0.94, 1.06)
	$SonidoLetras.play()
