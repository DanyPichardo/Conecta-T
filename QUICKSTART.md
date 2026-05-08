# INICIO RÁPIDO - Conecta-T

## Que es Conecta-T?

Conecta-T es un juego de estrategia basado en Connect Four (Cuatro en Línea) donde dos jugadores compiten por ser los primeros en formar una línea de 4 fichas de su color en un tablero de 7x6.

## Inicio en 2 Minutos

### Instalar
1. Descarga [Godot 4.0+](https://godotengine.org/download)
2. Abre la proyecto desde la carpeta `Conecta-T`

### Jugar
1. Presiona `F5` para ejecutar
2. Haz clic en una columna para colocar tu ficha
3. ¡Forma una línea de 4 para ganar!

## Estructura de Archivos

```
Conecta-T/
├── main.gdscene      ← ESCENA PRINCIPAL (ver esto primero)
├── main.gd          ← Lógica principal del juego
├── board.gd         ← Lógica del tablero 7x6
├── ui.gd            ← Interfaz de usuario
└── (documentación)
```

## Flujo del Juego

```
┌─────────────┐
│  Comienza   │
│ Jugador 1   │
└──────┬──────┘
	   │
	   ├─→ Clic en columna
	   │       │
	   ├───────┴─→ place_piece() ──→ ¿Válido?
	   │                                  │
	   │                            ┌─────┴─────┐
	   │                            │ No        │ Sí
	   │                      (Columna llena)  │
	   │                            │     ┌─────┴─────┐
	   │                            │     │ check_winner()
	   │                            │     │     │
	   │                            │     ├─────┴─────┐
	   │                            │     │ Sí        │ No
	   │                            │    WIN     ┌────┴──┐
	   │                            │            │ is_board_full()
	   │                            │            │     │
	   │                            │       ┌────┴─────┴────┐
	   │                            │       │ Sí            │ No
	   │                            │      DRAW      (Cambiar a Jugador 2)
	   │                            └────→ ─────────────┘
	   │
	   └──────────── (Reiniciar con ESPACIO)
```

## Controles

| Acción | Tecla/Botón |
|--------|------------|
| **Colocar Ficha** | Clic del ratón en columna |
| **Reiniciar** | ESPACIO |
| **Salir** | ESC |

## Como Funciona (Resumen Técnico)

### Modelo (board.gd)
```gdscript
# Tablero interno 7x6
var board = [
  [0, 0, 0, 0, 0, 0, 0],  # Fila 0 (arriba)
  [0, 0, 0, 0, 0, 0, 0],  # Fila 1
  ...
  [0, 0, 0, 0, 0, 0, 0]   # Fila 5 (abajo)
]

# 0 = vacío, 1 = Rojo, 2 = Amarillo

# Rastrear posición más baja por columna
next_row = [0, 0, 0, 0, 0, 0, 0]  # Próxima fila disponible
```

### Vista (main.gd)
```gdscript
# Dibujar tablero oscuro
draw_rect(...)

# Dibujar fichas colocadas
draw_circle(Vector2(x, y), radius, color)

# Dibujar línea ganadora
draw_line(start, end, Color.GREEN, 5.0)
```

### Controlador (main.gd)
```gdscript
# Recibir clic del ratón
_input(event)

# Calcular columna
col = get_column_from_position(mouse_x)

# Colocar ficha
place_piece(col)

# Verificar ganador
if board.check_winner(col, row, player):
	show_winner()
```

## Gañadores - Como se Detectan

Después de cada movimiento, se verifica en 4 direcciones:

```
Horizontal: ○ ○ ○ ○  (izquierda-derecha)
Vertical:   ○
			○
			○
			○  (arriba-abajo)

Diagonal:   ○
			  ○
				○
				  ○  (abajo-derecha)

Diagonal:         ○
				○
			  ○
			○  (arriba-derecha)
```

Cada dirección cuenta incrementally hacia adelante y atrás desde la posición. Si suma >= 4, ¡VICTORIA!

## Colores

| Elemento | Color |
|----------|-------|
| Jugador 1 |  Rojo |
| Jugador 2 |  Amarillo |
| Victoria |  Verde (línea) |
| Fondo | Gris oscuro |

## Extensiones Futuras

Busca comentarios en el código con `# TODO` o `# FIXME`:

```gdscript
# TODO: Agregar animación de caída
# TODO: Agregar sonidos
# TODO: Agregar IA
```

## Debugging

### Ver el estado del tablero
```gdscript
# Agregar en _ready() en main.gd:
for row in board.board:
	print(row)
```

Salida esperada después de algunos movimientos:
```
[0, 0, 0, 0, 0, 0, 0]
[0, 1, 0, 0, 0, 0, 0]
[0, 2, 0, 0, 0, 0, 0]
[0, 1, 0, 0, 0, 0, 0]
[0, 2, 0, 0, 0, 0, 0]
[1, 2, 1, 0, 0, 0, 0]
```

### Mensajes de Error Comunes

| Error | Causa | Solución |
|-------|-------|----------|
| "Invalid class_name" | Error en sintaxis .gd | Verificar `extends` |
| "Node not found" | @onready falla | Verificar nombres en .tscn |
| "No scene to run" | main.tscn no existe | Crear main.tscn |

## Licencia

Proyecto educativo - Materia: Videojuegos en Red (IL386)
Universidad de Guadalajara - Centro Universitario de Ciencias Exactas e Ingenierías

## Autores

- Daniel Pichardo (Lead Developer)
- Carlos Leyva (Game Logic & UI)
- Eduardo Mora (QA & Assets)

---

**¿Necesitas ayuda?** Revisa:
- README.md → Descripción general
- TECHNICAL.md → Detalles técnicos
- SPECIFICATIONS.md → Especificaciones
- INSTALL.md → Problemas de instalación
