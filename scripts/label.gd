extends Label

# =============================================================
# LABEL.GD — Contador de monedas en pantalla
# =============================================================
# Este script va en un nodo Label de la UI. Su único trabajo es
# mantener el texto del contador siempre sincronizado con los
# valores reales del juego, leyendo directamente desde Global.
# =============================================================

# _process se ejecuta en cada frame (diferente a _physics_process).
# Se usa aquí porque actualizar un texto es una tarea visual,
# no física, así que no necesita sincronizarse con el motor de físicas.
func _process(_delta):
	# Leemos 'monedas_actuales' y 'meta_monedas' del Singleton Global.
	# str() convierte los números enteros a texto para poder concatenarlos.
	# El resultado que se ve en pantalla es algo como: "Monedas: 3 / 10"
	text = "Monedas: " + str(Global.monedas_actuales) + " / " + str(Global.meta_monedas)
