extends Node2D

class_name GameManager

@export var num_fichas: int = 40

var board: Board
var ui_layer: Node
var board_visual: BoardVisual
var current_player: int = 1
var game_over: bool = false
var match_over: bool = false
var winner: int = 0

var score_player1: int = 0
var score_player2: int = 0
var round_number: int = 0

var turn_time_left: float = 33.0
var decorative_pieces = []

# --- VARIABLES DE RED ---
# Indica si estamos esperando a que el otro jugador se conecte
var waiting_for_players: bool = true

func _ready() -> void:
	board = get_node_or_null("Board") as Board
	ui_layer = get_node_or_null("UI")
	board_visual = get_node_or_null("BoardVisual") as BoardVisual

	if not board or not board_visual:
		return

	call_deferred("center_board")
	create_decorative_pieces()

	# Conectar señales de red
	Network.game_ready.connect(_on_game_ready)
	Network.player_disconnected.connect(_on_player_disconnected)

	# Si no hay conexión de red activa, jugar en local directamente
	if not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		waiting_for_players = false
		setup_game()
	else:
		# Mostrar pantalla de espera hasta que el servidor emita game_ready
		_show_waiting_screen()

func _show_waiting_screen() -> void:
	if ui_layer and ui_layer.has_method("show_waiting"):
		ui_layer.show_waiting()
	else:
		print("[Main] Esperando al segundo jugador...")

func _on_game_ready() -> void:
	waiting_for_players = false
	# Solo el servidor inicia la partida (elige el primer turno y lo sincroniza)
	if multiplayer.is_server():
		var start_player = randi_range(1, 2)
		_server_start_game(start_player)

func _on_player_disconnected(_player_number: int) -> void:
	game_over = true
	match_over = true
	if ui_layer and ui_layer.has_method("show_disconnected"):
		ui_layer.show_disconnected()

func center_board() -> void:
	if not board_visual or not board:
		return
		
	var screen_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	if screen_width == null or screen_width == 0:
		var viewport_size = get_viewport_rect().size
		screen_width = viewport_size.x

	var board_width: float = board.COLS * (BoardVisual.PIECE_SIZE + BoardVisual.PADDING)
	
	board_visual.position.x = (screen_width - board_width) / 2.0
	board_visual.position.y = 100.0

func _process(delta: float) -> void:
	if not decorative_pieces.is_empty():
		var viewport_size = get_viewport_rect().size
		for piece in decorative_pieces:
			piece["x"] += piece["velocity"].x * delta
			piece["y"] += piece["velocity"].y * delta
			
			if piece["x"] < -150 or piece["x"] > viewport_size.x + 150:
				piece["velocity"].x *= -1
			if piece["y"] < -150 or piece["y"] > viewport_size.y + 150:
				piece["velocity"].y *= -1
				
		_refresh_visual()

	# El temporizador lo decrementa el servidor (y el modo local).
	# El cliente también lo decrementa localmente para mostrar el display,
	# pero el servidor es quien lo reinicia con autoridad via RPC.
	var is_local = not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	var is_server: bool = not is_local and multiplayer.is_server()

	if not game_over and not match_over and not waiting_for_players:
		if turn_time_left > 0:
			turn_time_left -= delta
			if turn_time_left < 0:
				turn_time_left = 0
			# Solo el servidor (o modo local) actúa al agotarse el tiempo
			if turn_time_left <= 0 and (is_local or is_server):
				_server_timeout_turn()
		if ui_layer and ui_layer.has_method("update_timer_display"):
			ui_layer.update_timer_display(int(ceil(turn_time_left)))

func _server_timeout_turn() -> void:
	# El turno se venció: pasar al siguiente jugador sin colocar ficha
	turn_time_left = 33.0
	var next_player = 2 if current_player == 1 else 1
	sync_turn_change.rpc(next_player, turn_time_left)

func create_decorative_pieces() -> void:
	var viewport_size = get_viewport_rect().size
	decorative_pieces.clear()
	
	for i in range(num_fichas):
		var piece = {
			"size": randf_range(20.0, 75.0),
			"color": Color(1.0, 0.2, 0.2) if i % 2 == 0 else Color(1.0, 0.9, 0.0),
			"opacity": 1.0,
			"velocity": Vector2(randf_range(-70, 70), randf_range(-70, 70))
		}
		
		if i % 2 == 0:
			piece["x"] = randf_range(-200, viewport_size.x * 0.25)
		else:
			piece["x"] = randf_range(viewport_size.x * 0.75, viewport_size.x + 200)
			
		piece["y"] = randf_range(-100, viewport_size.y + 100)
		decorative_pieces.append(piece)

# Llamada solo por el servidor para arrancar la ronda inicial
func _server_start_game(start_player: int) -> void:
	board.reset_board()
	turn_time_left = 33.0
	game_over = false
	match_over = false
	winner = 0
	round_number = 0
	score_player1 = 0
	score_player2 = 0
	sync_setup_game.rpc(start_player)

func setup_game() -> void:
	board.reset_board()
	current_player = randi_range(1, 2)
	turn_time_left = 33.0
	game_over = false
	match_over = false 
	winner = 0
	round_number = 0
	score_player1 = 0
	score_player2 = 0
	
	if ui_layer and ui_layer.has_method("update_turn_display"):
		ui_layer.update_turn_display(current_player)
	if ui_layer and ui_layer.has_method("update_score_display"):
		ui_layer.update_score_display(score_player1, score_player2)
	_refresh_visual()

func _input(event: InputEvent) -> void:
	if not board or match_over or waiting_for_players:
		return
	
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return
	
	if game_over:
		return
	
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos = get_local_mouse_position()
			var local_mouse = mouse_pos - board_visual.position
			var col = get_column_from_position(local_mouse.x)
			
			if col >= 0 and col < board.COLS:
				_try_place_piece(col)
				get_tree().root.set_input_as_handled()

func _try_place_piece(col: int) -> void:
	var is_local = not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer is OfflineMultiplayerPeer

	if is_local:
		# Modo local: colocar directamente
		_local_place_piece(col)
		return

	# Modo red: verificar que es el turno del jugador local
	var my_number = Network.get_my_player_number()
	if my_number != current_player:
		return  # No es tu turno

	if multiplayer.is_server():
		# El host ES el servidor: ejecutar lógica directamente sin RPC
		_execute_server_place(col)
	else:
		# Cliente: enviar petición al servidor
		request_place_piece.rpc_id(1, col)

# Lógica local (sin red)
func _local_place_piece(col: int) -> void:
	if not board.place_piece(col, current_player):
		return

	var row = board.ROWS - board.next_row[col]
	turn_time_left = 33.0

	if board.check_winner(col, row, current_player):
		_handle_round_end(current_player, false)
	elif board.is_board_full():
		_handle_round_end(0, true)
	else:
		current_player = 2 if current_player == 1 else 1
		if ui_layer and ui_layer.has_method("update_turn_display"):
			ui_layer.update_turn_display(current_player)
	_refresh_visual()

func _handle_round_end(round_winner: int, is_draw: bool) -> void:
	game_over = true
	round_number += 1
	turn_time_left = 33.0

	if not is_draw:
		winner = round_winner

		# Solo sumar puntos en modo local.
		# En red, el servidor ya sincronizó los scores.
		var is_local = not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer is OfflineMultiplayerPeer

		if is_local:
			if round_winner == 1:
				score_player1 += 1
			else:
				score_player2 += 1

	_refresh_visual()

	if is_draw:
		if ui_layer and ui_layer.has_method("show_draw"):
			ui_layer.show_draw()
		_schedule_reset_round(2.0)
	else:
		if ui_layer and ui_layer.has_method("show_winner"):
			ui_layer.show_winner(round_winner)
		if ui_layer and ui_layer.has_method("update_score_display"):
			ui_layer.update_score_display(score_player1, score_player2)
		if score_player1 >= 3 or score_player2 >= 3:
			match_over = true
			var match_winner_name = "ROJO" if score_player1 >= 3 else "AMARILLO"
			_schedule_match_end(match_winner_name, 1.0)
		else:
			_schedule_reset_round(2.0)

func _schedule_reset_round(delay: float) -> void:
	var is_local = not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	# Solo el servidor (o el modo local) inicia el reset de ronda
	if not is_local and not multiplayer.is_server():
		return
	await get_tree().create_timer(delay).timeout
	reset_round()

func _schedule_match_end(winner_name: String, delay: float) -> void:
	var is_local = not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	if not is_local and not multiplayer.is_server():
		return
	await get_tree().create_timer(delay).timeout
	# Sincronizar pantalla de fin de partida a todos
	if is_local:
		show_match_winner_screen(winner_name)
	else:
		sync_match_end.rpc(winner_name)

@rpc("authority", "call_local", "reliable")
func sync_match_end(winner_name: String) -> void:
	show_match_winner_screen(winner_name)

func get_column_from_position(x: float) -> int:
	if x < 0:
		return -1
	var col_width: float = BoardVisual.PIECE_SIZE + BoardVisual.PADDING
	var board_width: float = board.COLS * col_width
	if x > board_width:
		return -1
	return int(x / col_width)

# ============================================================
# RPCs - Modelo Cliente-Servidor Autoritativo
# ============================================================

# El cliente le pide al servidor colocar una ficha
@rpc("any_peer", "call_remote", "reliable")
func request_place_piece(col: int) -> void:
	if not multiplayer.is_server():
		return

	var sender_id = multiplayer.get_remote_sender_id()
	# Validar que el sender corresponde al jugador del turno actual
	var sender_player = Network.player_assignments.get(sender_id, 0)
	if sender_player != current_player:
		return  # No es el turno de este jugador

	_execute_server_place(col)

# Lógica del servidor al colocar una ficha (usada por host y por el RPC)
func _execute_server_place(col: int) -> void:
	if not board.place_piece(col, current_player):
		return  # Columna inválida o llena

	var row = board.ROWS - board.next_row[col]
	var is_winner = board.check_winner(col, row, current_player)
	var is_draw = not is_winner and board.is_board_full()

	var next_player = 2 if current_player == 1 else 1
	var new_score1 = score_player1
	var new_score2 = score_player2

	if is_winner:
		if current_player == 1:
			new_score1 += 1
		else:
			new_score2 += 1

	# Avisar a todos (incluyendo al servidor mismo)
	sync_board_state.rpc(col, current_player, next_player, is_winner, is_draw, new_score1, new_score2)

# El servidor sincroniza el estado del tablero a todos
@rpc("authority", "call_local", "reliable")
func sync_board_state(col: int, player_that_moved: int, next_player: int, is_winner: bool, is_draw: bool, new_score1: int, new_score2: int) -> void:
	# Los clientes aplican el movimiento en su tablero local
	if not multiplayer.is_server():
		board.place_piece(col, player_that_moved)

	turn_time_left = 33.0
	current_player = next_player
	score_player1 = new_score1
	score_player2 = new_score2

	_refresh_visual()

	if is_winner:
		_handle_round_end(player_that_moved, false)
	elif is_draw:
		_handle_round_end(0, true)
	else:
		if ui_layer and ui_layer.has_method("update_turn_display"):
			ui_layer.update_turn_display(current_player)

# El servidor sincroniza el inicio del juego (con el turno inicial)
@rpc("authority", "call_local", "reliable")
func sync_setup_game(start_player: int) -> void:
	board.reset_board()
	current_player = start_player
	turn_time_left = 33.0
	game_over = false
	match_over = false
	winner = 0
	round_number = 0
	score_player1 = 0
	score_player2 = 0

	if ui_layer and ui_layer.has_method("update_turn_display"):
		ui_layer.update_turn_display(current_player)
	if ui_layer and ui_layer.has_method("update_score_display"):
		ui_layer.update_score_display(score_player1, score_player2)
	_refresh_visual()

# El servidor sincroniza un cambio de turno por tiempo agotado
@rpc("authority", "call_local", "reliable")
func sync_turn_change(next_player: int, new_time: float) -> void:
	current_player = next_player
	turn_time_left = new_time
	if ui_layer and ui_layer.has_method("update_turn_display"):
		ui_layer.update_turn_display(current_player)

# ============================================================

func show_match_winner_screen(winner_name: String) -> void:
	var overlay = CanvasLayer.new()
	overlay.layer = 100 
	add_child(overlay)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.85) 
	overlay.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 30)
	center.add_child(vbox)
	
	var label = Label.new()
	label.text = "¡EL JUGADOR " + winner_name + " GANA LA PARTIDA!"
	label.add_theme_font_size_override("font_size", 48)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2) if winner_name == "ROJO" else Color(1.0, 0.9, 0.0))
	vbox.add_child(label)
	
	var button = Button.new()
	button.text = "Volver a Jugar"
	button.add_theme_font_size_override("font_size", 32)
	button.pressed.connect(func(): 
		overlay.queue_free()
		if multiplayer.is_server() or not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
			_server_start_game(randi_range(1, 2))
	)
	vbox.add_child(button)

func _refresh_visual() -> void:
	if board_visual:
		board_visual.refresh()

func reset_round() -> void:
	if match_over:
		return
	board.reset_board()

	var is_local = not multiplayer.multiplayer_peer or multiplayer.multiplayer_peer is OfflineMultiplayerPeer
	if is_local or multiplayer.is_server():
		var next_player = randi_range(1, 2)
		if is_local:
			current_player = next_player
			turn_time_left = 33.0
			game_over = false
			winner = 0
			if ui_layer and ui_layer.has_method("update_turn_display"):
				ui_layer.update_turn_display(current_player)
			if ui_layer and ui_layer.has_method("update_score_display"):
				ui_layer.update_score_display(score_player1, score_player2)
			_refresh_visual()
		else:
			# Servidor sincroniza reset de ronda
			sync_reset_round.rpc(next_player)

@rpc("authority", "call_local", "reliable")
func sync_reset_round(next_player: int) -> void:
	board.reset_board()
	current_player = next_player
	turn_time_left = 33.0
	game_over = false
	winner = 0
	if ui_layer and ui_layer.has_method("update_turn_display"):
		ui_layer.update_turn_display(current_player)
	if ui_layer and ui_layer.has_method("update_score_display"):
		ui_layer.update_score_display(score_player1, score_player2)
	_refresh_visual()
