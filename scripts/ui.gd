extends CanvasLayer

class_name UI

var turn_label: Label
var score_label: Label
var timer_label: Label
var exit_button: Button

func _ready() -> void:
	turn_label = get_node_or_null("VBoxContainer/TurnLabel")
	score_label = get_node_or_null("ScoreLabel") 
	
	# =========================================================
	# 1. CREACIÓN DEL BOTÓN DE SALIDA 100% POR CÓDIGO
	# =========================================================
	exit_button = Button.new()
	exit_button.text = "✖"
	add_child(exit_button)
	
	# Posición (esquina superior izquierda) y tamaño
	exit_button.position = Vector2(20, 20)
	exit_button.size = Vector2(50, 30)
	exit_button.add_theme_font_size_override("font_size", 26)
	
	# Estilo oscuro con bordes redondeados para que se vea bien
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.15, 0.15, 0.15, 0.9) # Gris muy oscuro
	btn_style.set_corner_radius_all(10)
	exit_button.add_theme_stylebox_override("normal", btn_style)
	exit_button.add_theme_stylebox_override("hover", btn_style) # Al pasar el mouse
	
	# Conectar la acción de clic
	exit_button.pressed.connect(_on_exit_pressed)
	# =========================================================

	# 2. Configurar el Turn Label
	if turn_label:
		if turn_label.label_settings == null:
			turn_label.label_settings = LabelSettings.new()
		turn_label.label_settings.font_size = 48
		turn_label.label_settings.outline_size = 8
		turn_label.label_settings.outline_color = Color(0.2, 0.2, 0.2) 
	
	# 3. Crear el Reloj Dinámico
	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.label_settings = LabelSettings.new()
	timer_label.label_settings.font_size = 60 
	timer_label.label_settings.outline_size = 10
	add_child(timer_label)
	
	var viewport_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	if viewport_width == null or viewport_width == 0: viewport_width = 1152
	timer_label.position = Vector2((viewport_width / 2.0) - 100, 550) 
	timer_label.size = Vector2(200, 100)
	
	RenderingServer.set_default_clear_color(Color.WHITE)
	
	update_turn_display(1)
	update_score_display(0, 0)

func update_turn_display(player: int) -> void:
	if not turn_label:
		return
		
	var new_settings = LabelSettings.new()
	new_settings.font_size = 56
	new_settings.outline_size = 10
	new_settings.outline_color = Color(0.2, 0.2, 0.2)
		
	if player == 1:
		turn_label.text = "◀"
		new_settings.font_color = Color(0.85, 0.1, 0.1) 
	else:
		turn_label.text = "▶"
		new_settings.font_color = Color(0.95, 0.8, 0.0) 
		
	turn_label.label_settings = new_settings

func update_timer_display(time_left: int) -> void:
	if not timer_label or not timer_label.label_settings:
		return
		
	timer_label.text = "00:%02d" % time_left
	
	if time_left <= 5:
		timer_label.label_settings.font_color = Color.RED
		timer_label.label_settings.outline_color = Color.DARK_RED
	else:
		timer_label.label_settings.font_color = Color(1.0, 0.9, 0.0)
		timer_label.label_settings.outline_color = Color(1.0, 0.6, 0.65)

func update_score_display(score1: int, score2: int) -> void:
	pass

func show_winner(player: int) -> void:
	if turn_label and turn_label.label_settings:
		var color_name = "ROJO" if player == 1 else "AMARILLO"
		turn_label.text = "¡GANA %s!" % color_name
		turn_label.label_settings.font_color = Color.GREEN

func show_draw() -> void:
	if turn_label and turn_label.label_settings:
		turn_label.text = "¡EMPATE!"
		turn_label.label_settings.font_color = Color.GRAY

func show_waiting() -> void:
	if turn_label:
		if turn_label.label_settings == null:
			turn_label.label_settings = LabelSettings.new()
		turn_label.text = "Esperando\njugador 2..."
		turn_label.label_settings.font_color = Color(0.2, 0.8, 1.0)
		turn_label.label_settings.font_size = 36

func show_disconnected() -> void:
	if turn_label:
		if turn_label.label_settings == null:
			turn_label.label_settings = LabelSettings.new()
		turn_label.text = "¡Jugador\ndesconectado!"
		turn_label.label_settings.font_color = Color.RED
		turn_label.label_settings.font_size = 32

# Función que te devuelve al menú principal
func _on_exit_pressed() -> void:
	Network.disconnect_from_game()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
