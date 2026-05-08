# Conecta-T

## Descripción del Proyecto
Conecta-T es un videojuego de estrategia y lógica desarrollado en **Godot Engine 4**. El proyecto evoluciona la mecánica clásica de alinear fichas, integrando condiciones de victoria extendidas, gestión de tiempo real y un sistema de renderizado dinámico mediante código.

## Propósito
Este repositorio forma parte de las actividades académicas de la carrera de **Ingeniería en Computación** en el **Centro Universitario de Ciencias Exactas e Ingenierías (CUCEI)**. El objetivo es demostrar la implementación de algoritmos de detección de patrones, gestión de estados de juego y desarrollo de interfaces interactivas para entornos de red y locales.

## Mecánicas de Juego
* **Modos de Victoria:**
	* **Línea de 4:** Alinear cuatro fichas de forma horizontal, vertical o diagonal.
	* **Forma en T:** Estructura de 4 fichas formando una "T" en cualquiera de sus cuatro orientaciones.
* **Sistema de Turnos:** Temporizador activo de **33 segundos** por jugador.
* **Condición de Partida:** Enfrentamientos al mejor de 3 rondas (gana quien alcance 3 puntos).

## Estructura del Proyecto
El proyecto se organiza bajo una arquitectura modular de escenas y scripts:

### Núcleo de Lógica
* `board.gd`: Algoritmos de validación del tablero y detección de victoria (incluyendo lógica de T-Shape).
* `main.gd`: Controlador del ciclo de vida del juego, gestión de puntuaciones y flujo de escenas.
* `ui.gd`: Controlador de la interfaz de usuario en tiempo real (reloj, marcadores y alertas).

### Renderizado y Assets
* `board_visual.gd`: Script encargado del dibujo dinámico del tablero, sombras 3D y efectos de resaltado de victoria.
* `assets/`: Incluye texturas para fichas (`redDot.png`, `yellowdot.png`) y elementos de UI (`join.png`, `exit.png`, `tutorial.png`).

### Escenas Principales
* `menu.tscn`: Punto de entrada del juego con navegación hacia tutorial y créditos.
* `main.tscn`: Escena de juego principal donde se instancian el tablero y la lógica visual.

## Instalación
1. Clonar el repositorio.
2. Importar el proyecto en **Godot Engine 4.x**.
3. Ejecutar la escena `menu.tscn` (F5).

## Créditos
**Desarrolladores:**
* Gómez Mora, José Eduardo 
* Leyva Gómez, Carlos Fabian 
* Pichardo Sánchez, Daniel

**Institución:** CUCEI - Ingeniería en Computación (Generación 2026).
