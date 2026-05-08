extends Control

@export var num_fichas: int = 40
@export var hover_scale: Vector2 = Vector2(1.1, 1.1) 
@export var normal_scale: Vector2 = Vector2(1.0, 1.0) 
@export var transition_time: float = 0.1 

var decorative_pieces: Array = []
var bg_canvas: Node2D

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.WHITE)
	var color_rect = get_node_or_null("ColorRect")
	if color_rect: color_rect.hide()
	
	bg_canvas = Node2D.new()
	add_child(bg_canvas)
	move_child(bg_canvas, 0)
	bg_canvas.draw.connect(_on_canvas_draw)
	create_decorative_pieces()
	
	var play_btn = get_node_or_null("PlayButton")
	var exit_btn = get_node_or_null("ExitButton")
	var tutorial_btn = get_node_or_null("VBoxContainer/TutorialButton")
	var credits_btn = get_node_or_null("VBoxContainer/CreditsButton")
	
	var buttons = [play_btn, exit_btn, tutorial_btn, credits_btn]
	
	for btn in buttons:
		if btn:
			# Configurar la animación de Hover
			btn.mouse_entered.connect(_on_button_hover.bind(btn, true))
			btn.mouse_exited.connect(_on_button_hover.bind(btn, false))
			
			# Conexiones protegidas (¡SOLO conecta si no lo hiciste tú en el editor!)
			if btn == play_btn and not btn.pressed.is_connected(_on_play_pressed): 
				btn.pressed.connect(_on_play_pressed)
				
			if btn == exit_btn and not btn.pressed.is_connected(_on_exit_pressed): 
				btn.pressed.connect(_on_exit_pressed)
				
			if btn == tutorial_btn and not btn.pressed.is_connected(_on_tutorial_pressed): 
				btn.pressed.connect(_on_tutorial_pressed)
				
			if btn == credits_btn and not btn.pressed.is_connected(_on_credits_pressed): 
				btn.pressed.connect(_on_credits_pressed)

# --- ANIMACIÓN DE CRECIMIENTO ---
func _on_button_hover(btn: Button, is_hover: bool) -> void:
	if btn:
		# Centrar el pivote para que crezca desde el medio
		btn.pivot_offset = btn.size / 2.0 
		var target_scale = hover_scale if is_hover else normal_scale
		
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_BACK) # Rebote sutil
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(btn, "scale", target_scale, transition_time)

# --- LÓGICA DE FICHAS Y POPUPS ---
func create_decorative_pieces() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_width: float = viewport_size.x
	var screen_height: float = viewport_size.y
	
	for i in range(num_fichas):
		var piece = {
			"size": randf_range(20.0, 75.0),
			"color": Color(1.0, 0.2, 0.2) if i % 2 == 0 else Color(1.0, 0.9, 0.0),
			"x": randf_range(-100, screen_width + 100),
			"y": randf_range(-100, screen_height + 100),
			"velocity": Vector2(randf_range(-70, 70), randf_range(-70, 70))
		}
		decorative_pieces.append(piece)

func _process(delta: float) -> void:
	if decorative_pieces.is_empty() or not bg_canvas:
		return

	var viewport_size: Vector2 = get_viewport_rect().size
	var screen_width: float = viewport_size.x
	var screen_height: float = viewport_size.y
	
	for piece in decorative_pieces:
		piece["x"] += piece["velocity"].x * delta
		piece["y"] += piece["velocity"].y * delta
		if piece["x"] < -150 or piece["x"] > screen_width + 150: piece["velocity"].x *= -1
		if piece["y"] < -150 or piece["y"] > screen_height + 150: piece["velocity"].y *= -1
			
	bg_canvas.queue_redraw()

func _on_canvas_draw() -> void:
	for piece in decorative_pieces:
		bg_canvas.draw_circle(Vector2(piece["x"], piece["y"]), piece["size"], piece["color"])

func _on_play_pressed() -> void:
	_show_multiplayer_popup()

func _show_multiplayer_popup() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.8)
	canvas.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)

	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 320)
	center.add_child(panel)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.61, 0.72)
	style.set_corner_radius_all(20)
	panel.add_theme_stylebox_override("panel", style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)

	var title_lbl = Label.new()
	title_lbl.text = "MODO DE JUEGO"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title_lbl)
	
	var local_ip_lbl = Label.new()
	local_ip_lbl.text = "Tu IP: " + Network.get_local_ip()
	local_ip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	local_ip_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(local_ip_lbl)

	# Campo de IP para el cliente
	var ip_lbl = Label.new()
	ip_lbl.text = "IP del servidor (para unirse):"
	ip_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip_lbl.add_theme_font_size_override("font_size", 16)
	vbox.add_child(ip_lbl)

	var ip_input = LineEdit.new()
	ip_input.text = Network.get_local_ip()
	ip_input.placeholder_text = "Ej: 192.168.1.5"
	ip_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	ip_input.custom_minimum_size = Vector2(300, 40)
	ip_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ip_input.add_theme_font_size_override("font_size", 18)
	vbox.add_child(ip_input)

	# Botones
	var btn_style_host = StyleBoxFlat.new()
	btn_style_host.bg_color = Color(0.1, 0.6, 0.2)
	btn_style_host.set_corner_radius_all(10)

	var btn_style_join = StyleBoxFlat.new()
	btn_style_join.bg_color = Color(0.1, 0.3, 0.8)
	btn_style_join.set_corner_radius_all(10)

	var btn_style_close = StyleBoxFlat.new()
	btn_style_close.bg_color = Color(0.85, 0.1, 0.1)
	btn_style_close.set_corner_radius_all(10)

	var host_btn = Button.new()
	host_btn.text = "🏠 Crear Servidor (Host)"
	host_btn.custom_minimum_size = Vector2(280, 50)
	host_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	host_btn.add_theme_font_size_override("font_size", 18)
	host_btn.add_theme_stylebox_override("normal", btn_style_host)
	host_btn.add_theme_stylebox_override("hover", btn_style_host)
	host_btn.pressed.connect(func():
		canvas.queue_free()
		_on_host_pressed()
	)
	vbox.add_child(host_btn)

	var join_btn = Button.new()
	join_btn.text = "🔗 Unirse al Servidor"
	join_btn.custom_minimum_size = Vector2(280, 50)
	join_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	join_btn.add_theme_font_size_override("font_size", 18)
	join_btn.add_theme_stylebox_override("normal", btn_style_join)
	join_btn.add_theme_stylebox_override("hover", btn_style_join)
	join_btn.pressed.connect(func():
		Network.server_address = ip_input.text.strip_edges()
		canvas.queue_free()
		_on_join_pressed()
	)
	vbox.add_child(join_btn)

	var close_btn = Button.new()
	close_btn.text = "CANCELAR"
	close_btn.custom_minimum_size = Vector2(150, 40)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.add_theme_font_size_override("font_size", 16)
	close_btn.add_theme_stylebox_override("normal", btn_style_close)
	close_btn.add_theme_stylebox_override("hover", btn_style_close)
	close_btn.pressed.connect(func(): canvas.queue_free())
	vbox.add_child(close_btn)

func _on_host_pressed() -> void:
	Network.create_server()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_join_pressed() -> void:
	Network.join_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()

func _on_credits_pressed() -> void:
	create_popup("CRÉDITOS", "Desarrolladores:\n\nGómez Mora, José Eduardo 
Leyva Gómez, Carlos Fabian 
Pichardo Sánchez, Daniel\nMateria: 
Videojuegos en Red – IL386 
Impartida por:  
Mtra. Martha del Carmen Gutiérrez 
Salmerón")

func _on_tutorial_pressed() -> void:
	create_popup("TUTORIAL", "OBJETIVO:\nSé el primero en alinear 4 fichas.\n\nMODOS DE VICTORIA:\n1. LÍNEA: 4 fichas (H, V o Diagonal).\n2. FORMA EN T: 4 fichas formando una T en cualquier dirección.")

func create_popup(title: String, content: String) -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.8)
	canvas.add_child(bg)
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center_container)
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 350)
	center_container.add_child(panel) 
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.61, 0.72) 
	style.set_corner_radius_all(20)
	panel.add_theme_stylebox_override("panel", style)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	panel.add_child(margin)
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	var title_lbl = Label.new()
	title_lbl.text = title
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 36)
	vbox.add_child(title_lbl)
	var content_lbl = Label.new()
	content_lbl.text = content
	content_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_lbl.add_theme_font_size_override("font_size", 18)
	vbox.add_child(content_lbl)
	var close_btn = Button.new()
	close_btn.text = "CERRAR"
	close_btn.custom_minimum_size = Vector2(150, 50)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.85, 0.1, 0.1) 
	btn_style.set_corner_radius_all(10)
	close_btn.add_theme_stylebox_override("normal", btn_style)
	close_btn.add_theme_stylebox_override("hover", btn_style)
	close_btn.pressed.connect(func(): canvas.queue_free())
	vbox.add_child(close_btn)
