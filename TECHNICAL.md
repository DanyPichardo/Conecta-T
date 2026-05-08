# Documentación Técnica - Conecta-T

## Arquitectura del Proyecto

El juego utiliza una arquitectura modular basada en MVC (Model-View-Controller):

```
Board (Model)
├── Lógica pura del tablero
├── Validación de movimientos
└── Detección de ganador

Main (Controller + View)
├── Gestión de entrada
├── Comunicación Board-UI
└── Renderizado visual

UI (View)
├── Elementos visuales de UI
└── Información para el jugador
```

## Flujo de Juego

### Inicialización
1. `main.tscn` carga la escena principal
2. `main.gd` inicializa los nodos (Board y UI)
3. `_ready()` en Main.gd llama a `setup_game()`
4. Board se reinicia y el turno comienza con Jugador 1

### Loop de Juego
```
1. Jugador hace clic en una columna
2. _input() captura el evento del ratón
3. Se calcula la columna usando get_column_from_position()
4. place_piece() intenta colocar la ficha
5. Board valida y coloca la ficha en la matriz
6. Se verifica ganador/empate
7. Se alterna de jugador
8. queue_redraw() redibuja el tablero
```

### Detección de Victoria
El algoritmo `check_line()` en Board.gd:
1. Recibe posición (col, row) y jugador
2. Para cada dirección (horizontal, vertical, diagonal):
   - Cuenta fichas del mismo jugador hacia adelante
   - Cuenta fichas del mismo jugador hacia atrás
   - Si total >= 4, retorna true (victoria)

Las 4 direcciones verificadas:
- (1, 0) → Horizontal
- (0, 1) → Vertical
- (1, 1) → Diagonal /
- (1, -1) → Diagonal \

## Estructura de Datos

### Tablero Interno
```gdscript
var board: Array[Array]  # Array[7][6]
# 0 = vacío
# 1 = Jugador 1 (Rojo)
# 2 = Jugador 2 (Amarillo)
```

### Rastreo de Filas
```gdscript
var next_row: Array[int]  # Array[7]
# Almacena el próximo índice de fila disponible por columna
# next_row[col] < ROWS significa que hay espacio
# next_row[col] == ROWS significa columna llena
```

## Sistema de Coordenadas

### Pantalla
```
(0, 0)
+------ X (aumenta hacia la derecha)
|
|
Y (aumenta hacia abajo)


Ventana de juego:
- Ancho: ~550 píxeles
- Alto: ~550 píxeles
- Tablero comienza en (BOARD_OFFSET_X=50, BOARD_OFFSET_Y=100)
```

### Tablero Lógico
```
    0   1   2   3   4   5   6  (columnas)
  +---+---+---+---+---+---+---+
0 |   |   |   |   |   |   |   |
  +---+---+---+---+---+---+---+
1 |   |   |   |   |   |   |   |
  +---+---+---+---+---+---+---+
2 |   |   |   |   |   |   |   |
  +---+---+---+---+---+---+---+
3 |   |   |   |   |   |   |   |
  +---+---+---+---+---+---+---+
4 |   |   |   |   |   |   |   |
  +---+---+---+---+---+---+---+
5 |   |   |   |   |   |   |   |
  +---+---+---+---+---+---+---+
(filas)
```

## Conversión de Coordenadas

### Mouse a Columna
```gdscript
func get_column_from_position(x: float) -> int:
	var board_x = x - BOARD_OFFSET_X  # Restar offset
	var col = int(board_x / (PIECE_SIZE + PADDING))  # Dividir por ancho unitario
	return col
```

Ejemplo:
- Click en x=435
- board_x = 435 - 50 = 385
- col = 385 / 74 = 5.20... → 5 (columna 6)

### Posición del Tablero a Pantalla
```gdscript
var screen_x = BOARD_OFFSET_X + col * (PIECE_SIZE + PADDING) + PIECE_SIZE / 2
var screen_y = BOARD_OFFSET_Y + row * (PIECE_SIZE + PADDING) + PIECE_SIZE / 2
```

## Renderizado

### `_draw()`
Se ejecuta cada vez que se llama a `queue_redraw()`:
1. `draw_board()` - Dibuja fondo y círculos del tablero
2. `draw_pieces()` - Dibuja todas las fichas colocadas
3. `draw_winning_line()` - Si hay victoria, dibuja línea verde

### Leyenda de Colores
- **Rojo**: Jugador 1
- **Amarillo**: Jugador 2
- **Verde**: Línea ganadora
- **Azul oscuro**: Fondo del tablero
- **Negro**: Huecos del tablero

## Estados del Juego

```
┌─────────────┐
│   Jugando   │
└─────────────┘
       ↓
   Click en columna
       ↓
   ¿Columna llena?  ────→ No (vuelve a Jugando)
       ↓
      No
       ↓
   place_piece()
       ↓
   ¿Hay ganador?  ────→ Sí ────→ game_over = true
       ↓                          show_winner()
      No
       ↓
   ¿Tablero lleno?  ────→ Sí ────→ game_over = true
       ↓                           show_draw()
      No
       ↓
   Cambiar jugador
       ↓
   Vuelve a Jugando
```

## Cálculos de Rendimiento

- **Complejidad de check_winner()**: O(8) = O(1)
  - 4 direcciones × 2 búsquedas (adelante/atrás)
  
- **Complejidad de place_piece()**: O(1)
  - Acceso a array + actualización
  
- **Complejidad de draw()**: O(ROWS × COLS) = O(42)
  - Se dibuja cada vez que cambia el estado

## Extensiones Futuras Posibles

1. **Sistema de Puntuación**: Rastrear victorias por jugador
2. **Modo IA**: Computadora como segundo jugador
3. **Animaciones**: Caída gradual de fichas con movimiento
4. **Sonidos**: Efectos al colocar fichas, ganar, etc.
5. **Niveles de Dificultad**: Si se agrega IA
6. **Historial de Movimientos**: Cola de últimos 10 movimientos
7. **Guardado de Partida**: Guardar y cargar estado del juego
8. **Modo de Red**: Dos clientes conectados (original)

## Testing

### Tests Unitarios Sugeridos
```gdscript
# Validar columna llena
assert not board.place_piece(2, 1) after 6 placements

# Validar victoria horizontal
place_pieces_horizontal()
assert board.check_winner(...)

# Validar victoria vertical
place_pieces_vertical()
assert board.check_winner(...)

# Validar empate
fill_board_no_winner()
assert board.is_board_full()
```

## Notas de Debug

### Para ver el estado interno del tablero:
```gdscript
# Agregar en _ready() o en un punto de ruptura
for row in board.board:
	print(row)
```

### Para visualizar columnas:
```gdscript
print("Next rows: ", board.next_row)
```

### Para validar línea ganadora:
```gdscript
print("Winner check: col=%d, row=%d, player=%d" % [col, row, player])
```
