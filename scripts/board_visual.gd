extends Node2D

class_name BoardVisual

const PIECE_SIZE = 64.0
const PADDING = 10.0
const COLS = 7
const ROWS = 6

const COLOR_BACKGROUND = Color.WHITE
const COLOR_BOARD = Color(0.12, 0.61, 0.72) 
const COLOR_PIECE_RED = Color(1.0, 0.2, 0.2) 
const COLOR_PIECE_YELLOW = Color(1.0, 0.9, 0.0) 
const COLOR_HIGHLIGHT = Color(0.0, 1.0, 0.0) 
const COLOR_SCORE_PIECE_BG = Color(0.1, 0.5, 0.6)

var board: Board
var game_manager: GameManager

func _ready() -> void:
	board = get_parent().get_node_or_null("Board") as Board
	game_manager = get_parent() as GameManager

	if not board or not game_manager:
		return

func refresh() -> void:
	if board:
		queue_redraw()

func _draw() -> void:
	if not board or not game_manager:
		return

	if not game_manager.decorative_pieces.is_empty():
		draw_decorative_pieces()

	draw_score_boards()
	draw_board()
	draw_pieces()

	if game_manager.game_over and game_manager.winner > 0:
		draw_winning_line()

func draw_board() -> void:
	var board_width = COLS * (PIECE_SIZE + PADDING)
	var board_height = ROWS * (PIECE_SIZE + PADDING)
	
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_BOARD
	style.set_corner_radius_all(20)
	style.shadow_color = Color(0, 0, 0, 0.3) 
	style.shadow_size = 12                   
	style.shadow_offset = Vector2(8, 8)      
	
	draw_style_box(style, Rect2(0, 0, board_width, board_height))
	
	for row in range(ROWS):
		for col in range(COLS):
			var x = col * (PIECE_SIZE + PADDING) + PIECE_SIZE / 2.0
			var y = row * (PIECE_SIZE + PADDING) + PIECE_SIZE / 2.0
			
			draw_circle(Vector2(x, y), PIECE_SIZE / 2.0, Color(0.1, 0.1, 0.1, 0.5))
			draw_circle(Vector2(x, y), PIECE_SIZE / 2.0 - 2.0, Color.BLACK)

func draw_pieces() -> void:
	var board_state = board.get_board_state()
	
	for row in range(ROWS):
		for col in range(COLS):
			var piece = board_state[row][col]
			if piece > 0:
				var x = col * (PIECE_SIZE + PADDING) + PIECE_SIZE / 2.0
				var y = row * (PIECE_SIZE + PADDING) + PIECE_SIZE / 2.0
				
				var color = COLOR_PIECE_RED if piece == 1 else COLOR_PIECE_YELLOW
				
				draw_circle(Vector2(x + 3, y + 3), PIECE_SIZE / 2.0 - 5.0, Color.BLACK)
				draw_circle(Vector2(x, y), PIECE_SIZE / 2.0 - 6.0, color)

func draw_winning_line() -> void:
	var board_state: Array = board.get_board_state()
	var winner: int = game_manager.winner

	# [delta_col, delta_row] for each line direction
	var directions: Array[Array] = [[1, 0], [0, 1], [1, 1], [1, -1]]
	for dir in directions:
		var dc: int = dir[0]
		var dr: int = dir[1]
		for row in range(ROWS):
			for col in range(COLS):
				var end_col: int = col + dc * 3
				var end_row: int = row + dr * 3
				if end_col < 0 or end_col >= COLS or end_row < 0 or end_row >= ROWS:
					continue
				if (board_state[row][col] == winner
						and board_state[row + dr][col + dc] == winner
						and board_state[row + dr * 2][col + dc * 2] == winner
						and board_state[row + dr * 3][col + dc * 3] == winner):
					draw_line(_cell_center(col, row), _cell_center(end_col, end_row), COLOR_HIGHLIGHT, 5.0)
					return

	highlight_t_shape()


func _cell_center(col: int, row: int) -> Vector2:
	return Vector2(
		col * (PIECE_SIZE + PADDING) + PIECE_SIZE / 2.0,
		row * (PIECE_SIZE + PADDING) + PIECE_SIZE / 2.0
	)


func _draw_highlight(c: int, r: int) -> void:
	draw_circle(_cell_center(c, r), PIECE_SIZE / 2.0 + 3.0, COLOR_HIGHLIGHT)

func highlight_t_shape() -> void:
	var board_state: Array = board.get_board_state()
	var winner: int = game_manager.winner
	
	for r in range(ROWS):
		for c in range(COLS):
			if board_state[r][c] == winner:
				
				# T Normal
				if r >= 1 and c >= 1 and c <= COLS - 2:
					if board_state[r-1][c] == winner and board_state[r][c-1] == winner and board_state[r][c+1] == winner:
						_draw_highlight(c, r)
						_draw_highlight(c, r-1)
						_draw_highlight(c-1, r)
						_draw_highlight(c+1, r)
						return
				
				# T Invertida
				if r <= ROWS - 2 and c >= 1 and c <= COLS - 2:
					if board_state[r+1][c] == winner and board_state[r][c-1] == winner and board_state[r][c+1] == winner:
						_draw_highlight(c, r)
						_draw_highlight(c, r+1)
						_draw_highlight(c-1, r)
						_draw_highlight(c+1, r)
						return
				
				# T Izquierda
				if c >= 1 and r >= 1 and r <= ROWS - 2:
					if board_state[r][c-1] == winner and board_state[r-1][c] == winner and board_state[r+1][c] == winner:
						_draw_highlight(c, r)
						_draw_highlight(c-1, r)
						_draw_highlight(c, r-1)
						_draw_highlight(c, r+1)
						return
				
				# T Derecha
				if c <= COLS - 2 and r >= 1 and r <= ROWS - 2:
					if board_state[r][c+1] == winner and board_state[r-1][c] == winner and board_state[r+1][c] == winner:
						_draw_highlight(c, r)
						_draw_highlight(c+1, r)
						_draw_highlight(c, r-1)
						_draw_highlight(c, r+1)
						return

func draw_decorative_pieces() -> void:
	for piece in game_manager.decorative_pieces:
		var color: Color = piece["color"]
		color.a = 1.0
		draw_circle(Vector2(piece["x"], piece["y"]), piece["size"], color)

func draw_score_boards() -> void:
	var piece_radius = 35.0  
	var gap = 20.0           
	var margin = 24.0        
	
	var panel_width = (piece_radius * 2) + (margin * 2)
	var panel_height = (piece_radius * 2 * 3) + (gap * 2) + (margin * 2)
	
	var main_board_width = COLS * (PIECE_SIZE + PADDING)
	var main_board_height = ROWS * (PIECE_SIZE + PADDING)
	
	var panel_top_y = (main_board_height - panel_height) / 2.0
	
	var red_center_x = -130.0 
	var yellow_center_x = main_board_width + 130.0 
	
	var p1_score = game_manager.get("score_player1") if game_manager.get("score_player1") != null else 0
	var p2_score = game_manager.get("score_player2") if game_manager.get("score_player2") != null else 0

	var style_red = StyleBoxFlat.new()
	style_red.bg_color = COLOR_PIECE_RED
	style_red.set_corner_radius_all(20)
	style_red.shadow_color = Color(0, 0, 0, 0.3)
	style_red.shadow_size = 10
	style_red.shadow_offset = Vector2(6, 6)

	var red_panel_x = red_center_x - (panel_width / 2.0)
	draw_style_box(style_red, Rect2(red_panel_x, panel_top_y, panel_width, panel_height))
	
	for i in range(3):
		var cx = red_center_x
		var cy = panel_top_y + panel_height - margin - piece_radius - (i * (piece_radius * 2 + gap))
		
		draw_circle(Vector2(cx, cy), piece_radius, Color(0.1, 0.1, 0.1, 0.5))
		draw_circle(Vector2(cx, cy), piece_radius - 2.0, Color.BLACK)
		
		if i < p1_score:
			draw_circle(Vector2(cx + 2, cy + 2), piece_radius - 3.0, Color.BLACK)
			draw_circle(Vector2(cx, cy), piece_radius - 4.0, COLOR_PIECE_YELLOW)
			
	var style_yellow = StyleBoxFlat.new()
	style_yellow.bg_color = COLOR_PIECE_YELLOW
	style_yellow.set_corner_radius_all(20)
	style_yellow.shadow_color = Color(0, 0, 0, 0.3)
	style_yellow.shadow_size = 10
	style_yellow.shadow_offset = Vector2(6, 6)

	var yellow_panel_x = yellow_center_x - (panel_width / 2.0)
	draw_style_box(style_yellow, Rect2(yellow_panel_x, panel_top_y, panel_width, panel_height))
	
	for i in range(3):
		var cx = yellow_center_x
		var cy = panel_top_y + panel_height - margin - piece_radius - (i * (piece_radius * 2 + gap))
		
		draw_circle(Vector2(cx, cy), piece_radius, Color(0.1, 0.1, 0.1, 0.5))
		draw_circle(Vector2(cx, cy), piece_radius - 2.0, Color.BLACK)
		
		if i < p2_score:
			draw_circle(Vector2(cx + 2, cy + 2), piece_radius - 3.0, Color.BLACK)
			draw_circle(Vector2(cx, cy), piece_radius - 4.0, COLOR_PIECE_RED)
