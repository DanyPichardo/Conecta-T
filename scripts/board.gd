extends Node2D

class_name Board

const COLS = 7
const ROWS = 6

# Estados: 0 = vacío, 1 = jugador 1 (rojo), 2 = jugador 2 (amarillo)
var board: Array[Array]
var next_row: Array[int]  # Rastrea la siguiente fila disponible por columna

signal piece_placed(col: int, row: int, player: int)
signal board_updated

func _ready() -> void:
	initialize_board()

func initialize_board() -> void:
	board = []
	next_row = []
	
	for row in range(ROWS):
		var new_row: Array[int] = []
		for col in range(COLS):
			new_row.append(0)
		board.append(new_row)
	
	for col in range(COLS):
		next_row.append(0)

func place_piece(col: int, player: int) -> bool:
	if col < 0 or col >= COLS:
		return false
	
	if next_row[col] >= ROWS:
		return false
	
	var row = ROWS - 1 - next_row[col]
	board[row][col] = player
	next_row[col] += 1
	
	piece_placed.emit(col, row, player)
	board_updated.emit()
	
	return true

func check_winner(col: int, row: int, player: int) -> bool:
	# 1. Verificar línea de 4 (horizontal, vertical, diagonal)
	if check_line(col, row, 1, 0, player): return true
	if check_line(col, row, 0, 1, player): return true
	if check_line(col, row, 1, 1, player): return true
	if check_line(col, row, 1, -1, player): return true
	
	# 2. Verificar forma de T (Escaneo completo del tablero)
	if check_t_shape(player):
		return true
	
	return false

# --- NUEVA LÓGICA DE DETECCIÓN DE T ---
func check_t_shape(player: int) -> bool:
	# Escaneamos cada celda del tablero asumiendo que podría ser el CENTRO de una T
	for r in range(ROWS):
		for c in range(COLS):
			if board[r][c] == player:
				
				# T Normal (apuntando hacia arriba)
				if r >= 1 and c >= 1 and c <= COLS - 2:
					if board[r-1][c] == player and board[r][c-1] == player and board[r][c+1] == player:
						return true
				
				# T Invertida (apuntando hacia abajo)
				if r <= ROWS - 2 and c >= 1 and c <= COLS - 2:
					if board[r+1][c] == player and board[r][c-1] == player and board[r][c+1] == player:
						return true
				
				# T apuntando a la Izquierda
				if c >= 1 and r >= 1 and r <= ROWS - 2:
					if board[r][c-1] == player and board[r-1][c] == player and board[r+1][c] == player:
						return true
				
				# T apuntando a la Derecha
				if c <= COLS - 2 and r >= 1 and r <= ROWS - 2:
					if board[r][c+1] == player and board[r-1][c] == player and board[r+1][c] == player:
						return true
						
	return false

func check_line(col: int, row: int, dx: int, dy: int, player: int) -> bool:
	var count = 1
	
	var x = col + dx
	var y = row + dy
	while x >= 0 and x < COLS and y >= 0 and y < ROWS:
		if board[y][x] == player:
			count += 1
			x += dx
			y += dy
		else:
			break
	
	x = col - dx
	y = row - dy
	while x >= 0 and x < COLS and y >= 0 and y < ROWS:
		if board[y][x] == player:
			count += 1
			x -= dx
			y -= dy
		else:
			break
	
	return count >= 4

func is_board_full() -> bool:
	for col in range(COLS):
		if next_row[col] < ROWS:
			return false
	return true

func get_piece_at(col: int, row: int) -> int:
	if col < 0 or col >= COLS or row < 0 or row >= ROWS:
		return 0
	return board[row][col]

func get_board_state() -> Array[Array]:
	return board

func reset_board() -> void:
	initialize_board()
