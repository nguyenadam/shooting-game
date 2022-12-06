extends Node

const DEFAULT_PORT = 28960
const MAX_CLIENTS = 6

var server = null
var client = null

var ip_address = ""
var player_count = 0

func _ready() -> void:
	ip_address = IP.get_local_addresses()[0]
	print("Possible Addresses: " + str(IP.get_local_addresses()))
	print("Selected: " + ip_address)

	get_tree().connect("connected_to_server", self, "_connected_to_server")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

func create_server() -> void:
	server = NetworkedMultiplayerENet.new()
	server.create_server(DEFAULT_PORT, MAX_CLIENTS)
	get_tree().set_network_peer(server)
	player_count = 1

func join_server() -> void:
	client = NetworkedMultiplayerENet.new()
	var output = client.create_client(ip_address, DEFAULT_PORT)
	get_tree().set_network_peer(client)

func _connected_to_server() -> void:
	print("Sucessfully connected to server")

func _server_disconnected() -> void:
	print("Disconnected from server")
