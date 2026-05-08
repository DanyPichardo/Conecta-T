# Conecta-T - Documentación del Proyecto

## 1. Descripción General

Conecta-T es un videojuego de estrategia desarrollado en Godot Engine 4 que evoluciona la mecánica clásica de Connect Four. Es un proyecto académico de la carrera de Ingeniería en Computación del CUCEI, diseñado como base para futuras extensiones de red.

El juego implementa un tablero de 7x6 con detección automática de patrones de victoria en cuatro direcciones. Soporta modo local para dos jugadores alternados con temporizador de 33 segundos por turno.

**Desarrolladores:** José Eduardo Gómez Mora, Carlos Fabian Leyva Gómez, Daniel Pichardo Sánchez.

## 2. Funcionalidades Implementadas

### 2.1 Lógica del Juego
- Tablero interno de matriz 7x6 con estados (vacío, Jugador 1, Jugador 2)
- Colocación de fichas con validación de columnas llenas
- Sistema de turnos alternado automático
- Detección de empate cuando el tablero se llena sin ganador

### 2.2 Detección de Victoria
- Búsqueda en cuatro direcciones: horizontal, vertical, diagonal ascendente y diagonal descendente
- Algoritmo optimizado O(1): máximo 8 iteraciones (4 direcciones × 2 búsquedas)
- Validación de líneas de 4 o más fichas consecutivas del mismo jugador

### 2.3 Sistema Visual
- Renderizado dinámico del tablero mediante código (no sprites predefinidos)
- Fichas diferenciadas por color: rojo (Jugador 1), amarillo (Jugador 2)
- Línea ganadora resaltada en verde con grosor visible
- Tablero de fondo gris oscuro (DARK_SLATE_GRAY)
- Sombras 3D simuladas en la visualización

### 2.4 Interfaz de Usuario
- Indicador en tiempo real del turno actual
- Mensajes de victoria/empate prominentes
- Instrucciones en pantalla
- Controles responsivos (clic del ratón)
- Resolutución soportadas desde 640x480 hasta 4K

### 2.5 Entrada y Control
- Clic del ratón para colocar fichas (mapeo automático de columnas)
- Tecla ESPACIO para reiniciar partida
- Tecla ESC para salir
- Prevención de movimientos durante game over

### 2.6 Arquitectura
- Patrón MVC (Model-View-Controller):
  - Board.gd: Lógica pura, validaciones y detección de patrones
  - Main.gd: Controlador y lógica visual
  - UI.gd: Interfaz de usuario
- Comunicación por señales entre componentes
- Código modular y extensible

## 3. Problemas Encontrados y Soluciones Aplicadas

### 3.1 Detección de Patrones Complejos
**Problema:** Validar correctamente líneas de fichas en cuatro direcciones diferentes sin contar la misma ficha múltiples veces.

**Solución:** Algoritmo bidireccional que cuenta fichas del mismo jugador tanto hacia adelante como hacia atrás desde la posición colocada, sumando ambas direcciones. Si el total es >= 4, se registra victoria.

### 3.2 Conversión de Coordenadas Mouse a Tablero
**Problema:** Mapear correctamente la posición del clic del ratón a la columna correcta del tablero lógico.

**Solución:** Función de conversión que resta el offset del tablero y divide entre el ancho unitario (tamaño de ficha + padding). Incluye validación de límites.

### 3.3 Sincronización Entre Modelos Internos
**Problema:** Mantener consistencia entre el estado del tablero y las posiciones visuales durante el renderizado.

**Solución:** Sistema de next_row que rastrea la próxima fila disponible por columna. Evita búsquedas innecesarias y asegura consistencia.

### 3.4 Rendimiento en Tableros Grandes
**Problema:** Potencial degradación de rendimiento con resoluciones altas.

**Solución:** Complejidad O(1) para operaciones críticas (place_piece, check_winner) y O(42) para renderizado máximo. Performance objetivo: 60 FPS, mínimo aceptable 30 FPS.

### 3.5 Gestión de Estados
**Problema:** Evitar que el jugador siga jugando después de Victoria/Empate.

**Solución:** Flag game_over que bloquea entrada de usuario hasta reinicio explícito con ESPACIO.

## 4. Especificaciones Técnicas

| Aspecto | Valor |
|--------|-------|
| Tablero | 7 columnas × 6 filas (42 celdas) |
| Tamaño de ficha | 64 píxeles de diámetro |
| Sistema de turnos | 33 segundos por jugador |
| Lenguaje | GDScript |
| Engine | Godot Engine 4.0+ |
| Arquitectura | MVC |
| Complejidad crítica | O(1) |

| Componente | Tamaño |
|-----------|--------|
| Array de tablero | 42 integers |
| Array de next_row | 7 integers |
| Variables globales | ~200 bytes |
| **Total** | ~1 KB |

| Requisito | Mínimo | Recomendado |
|----------|--------|------------|
| Procesador | Intel Pentium 4 GHz | Intel i5 2.0 GHz |
| RAM | 512 MB | 1 GB |
| GPU | Intel HD 2000+ | GPU dedicada |
| Resolución | 640x480 | 1920x1080 |

## 5. Plan de Implementación de Red TCP (Fase 2)

### 5.1 Arquitectura Propuesta

```
Cliente 1 (Jugador 1)
    |
    | [TCP Socket]
    |
Servidor Central
    |
    | [TCP Socket]
    |
Cliente 2 (Jugador 2)
```

### 5.2 Protocolo de Comunicación

#### Mensajes Base
Formato: `[TIPO_MENSAJE]|[DATOS]`

| Tipo | Datos | Descripción |
|------|-------|------------|
| CONNECT | nombre_jugador | Conexión inicial |
| MOVE | columna | Colocación de ficha |
| STATE | tablero_json | Sincronización de estado |
| TURN | jugador_id | Cambio de turno |
| WIN | ganador_id | Notificación de victoria |
| DRAW | - | Notificación de empate |
| DISCONNECT | - | Desconexión |

#### Flujo de Partida en Red
1. Ambos clientes se conectan al servidor
2. Servidor asigna IDs de jugador (1 y 2)
3. Cliente 1 comienza
4. Al hacer movimiento, cliente envía `MOVE|columna`
5. Servidor valida en su instancia de Board
6. Servidor envía `STATE|tablero` a ambos clientes
7. Servidores calcula ganador/empate
8. Si hay resultado, envía `WIN|id` o `DRAW`
9. Clientes reciben y sincronizan localmente

### 5.3 Componentes a Implementar

#### Servidor (server.gd)
- Escucha en puerto TCP (ej: 8888)
- Mantiene dos instancias de Board (una por sesión activa)
- Valida movimientos antes de aceptarlos
- Distribuye estado a ambos clientes
- Detecta desconexiones y cierra partidas

#### Cliente (client.gd)
- Se conecta al servidor por IP y puerto
- Recibe ESTADO y actualiza Board local
- Envía movimientos del usuario
- Recibe notificaciones de victoria/empate/turno

#### Sincronización
- Tablero se sincroniza tras cada movimiento válido
- Checksum para validar consistencia
- Timeout de 5 segundos para respuesta de servidor

### 5.4 Manejo de Errores en Red

| Escenario | Acción |
|-----------|--------|
| Conexión rechazada | Mostrar error y volver a menú |
| Desconexión inesperada | Pausar juego, intentar reconexión (3 intentos) |
| Movimiento inválido | Servidor rechaza y notifica al cliente |
| Tablero desincronizado | Servidor envía estado completo forzado |
| Timeout de respuesta | Reconexión automática o cancelación |

### 5.5 Consideraciones de Seguridad

- Validación de entrada en servidor (rango columna 0-6)
- Verificación de turno antes de aceptar movimiento
- Límite de conexiones simultáneas (máximo 2 por partida)
- Timeout de sesión inactiva (5 minutos)
- No se permite cambio de ID de jugador durante partida

### 5.6 Estrategia de Implementación

**Fase 2a (Semana 1-2):**
- Crear clase NetworkManager que envuelva TCPServer/TCPClient de Godot
- Implementar protocolo de conexión y desconexión
- Crear servidor básico que acepta dos conexiones

**Fase 2b (Semana 3-4):**
- Integrar sincronización de estado del tablero
- Implementar validación de movimientos en servidor
- Agregar manejo de desconexiones

**Fase 2c (Semana 5-6):**
- Testing con dos clientes simultáneos
- Simulación de latencia y pérdida de paquetes
- Optimización de tráfico (solo enviar cambios, no tablero completo)

**Fase 2d (Semana 7-8):**
- Interfaz de conexión (IP, puerto, nombre de jugador)
- Lobby de espera de jugador
- Despliegue en servidor Linux

### 5.7 Cambios a Arquitectura Existente

- Separar lógica de Board (mantener como está)
- Main.gd: Agregar manejo de eventos de red
- UI.gd: Agregar pantalla de conexión y estado de red
- Crear scripts nuevos:
  - network_manager.gd (gestión TCP)
  - server.gd (lado servidor)
  - protocol.gd (definición de mensajes)

### 5.8 Beneficios y Limitaciones

**Beneficios:**
- Bajo overhead de ancho de banda (mensajes pequeños)
- Latencia baja con TCP
- Escalable a múltiples partidas simultáneas

**Limitaciones:**
- TCP agregará latencia de round-trip (~50-200ms)
- Requiere servidor dedicado permanentemente conectado
- No soporta jugadores detrás de NAT sin port-forwarding

## 6. Roadmap Completo

| Fase | Componente | Estado | Fecha Estimada |
|------|-----------|--------|-----------------|
| 1 | Juego local completo | Completado | Abril 2026 |
| 2 | Red TCP bidireccional | Planeado | Mayo-Junio 2026 |
| 3 | Animaciones y sonido | Planeado | Julio 2026 |
| 4 | Sistema de IA | Planeado | Agosto 2026 |
| 5 | Persistencia de datos | Planeado | Septiembre 2026 |

## 7. Conclusión

Conecta-T Fase 1 está completamente funcional como juego local con arquitectura sólida. La transición a red en Fase 2 será sencilla gracias al patrón MVC que permite agregar capas de networking sin modificar lógica de juego crítica.

La implementación TCP propuesta balance seguridad, confiabilidad y simplicidad de desarrollo, siendo adecuada para entorno académico y extensible para producción.

---

**Última actualización:** Abril 21, 2026  
**Versión del documento:** 1.0
