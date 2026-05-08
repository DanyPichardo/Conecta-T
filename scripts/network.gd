extends Node

const PORT = 7000
const MAX_PLAYERS = 2

# player_id -> player_number (1 o 2)
var player_assignments: Dictionary = {}

# Número de jugador de esta instancia (1 = host, 2 = cliente)
var my_player_number: int = 0

# IP para conectarse (puede cambiarse antes de llamar join_game)
var server_address: String = "127.0.0.1"

signal player_number_assigned(player_number: int)
signal game_ready()
signal player_disconnected(player_number: int)

func get_local_ip() -> String:
	var ips = IP.get_local_addresses()

	var blocked_prefixes = [
		"127.",
		"169.254.",
		"192.168.56.",   # VirtualBox
		"192.168.122.",  # KVM
		"192.168.224.",  # Hyper-V
		"172.17.",       # Docker
	]

	for ip in ips:
		if ":" in ip:
			continue

		var blocked = false

		for prefix in blocked_prefixes:
			if ip.begins_with(prefix):
				blocked = true
				break

		if blocked:
			continue

		if ip.begins_with("192.168.") \
		or ip.begins_with("10.") \
		or ip.begins_with("172."):
			return ip
			
	return "127.0.0.1"

func create_server() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_server(PORT, MAX_PLAYERS)
	if err != OK:
		push_error("Error al crear el servidor: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	# El host siempre es el Jugador 1
	my_player_number = 1
	player_assignments[1] = 1
	var local_ip = get_local_ip()
	print("[Network] Servidor iniciado")
	print("[Network] IP Local: %s" % local_ip)
	print("[Network] Puerto: %d" % PORT)
	print("[Network] Esperando jugador 2...")

func join_game() -> void:
	var peer = ENetMultiplayerPeer.new()
	var err = peer.create_client(server_address, PORT)
	if err != OK:
		push_error("Error al conectarse al servidor: %s" % err)
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	print("[Network] Conectando a %s:%d..." % [server_address, PORT])

# --- SEÑALES DEL SERVIDOR ---

func _on_peer_connected(id: int) -> void:
	# Solo el servidor asigna números de jugador
	if not multiplayer.is_server():
		return

	# Asignar número de jugador al nuevo par
	var player_number = player_assignments.size() + 1
	player_assignments[id] = player_number
	print("[Network] Jugador %d conectado (ID: %d)" % [player_number, id])

	# Decirle al cliente cuál es su número de jugador
	assign_player_number.rpc_id(id, player_number)

	# Si ya tenemos 2 jugadores, iniciar el juego en todos
	if player_assignments.size() >= MAX_PLAYERS:
		print("[Network] ¡Ambos jugadores conectados! Iniciando partida...")
		start_game.rpc()

func _on_peer_disconnected(id: int) -> void:
	if not multiplayer.is_server():
		return
	var player_number = player_assignments.get(id, 0)
	player_assignments.erase(id)
	print("[Network] Jugador %d desconectado (ID: %d)" % [player_number, id])
	player_disconnected.emit(player_number)

# --- SEÑALES DEL CLIENTE ---

func _on_connected_to_server() -> void:
	print("[Network] Conectado al servidor. Esperando asignación de jugador...")

func _on_connection_failed() -> void:
	push_error("[Network] Falló la conexión al servidor.")
	multiplayer.multiplayer_peer = null

func _on_server_disconnected() -> void:
	print("[Network] El servidor se desconectó.")
	multiplayer.multiplayer_peer = null
	player_disconnected.emit(0)

# --- RPCs ---

@rpc("authority", "call_remote", "reliable")
func assign_player_number(player_number: int) -> void:
	my_player_number = player_number
	print("[Network] Soy el Jugador %d" % my_player_number)
	player_number_assigned.emit(player_number)

@rpc("authority", "call_local", "reliable")
func start_game() -> void:
	print("[Network] ¡La partida comienza!")
	game_ready.emit()

func get_my_player_number() -> int:
	return my_player_number

func disconnect_from_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	player_assignments.clear()
	my_player_number = 0
