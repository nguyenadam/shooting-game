extends Control

onready var multiplayer_config_ui = $MultiplayerConfigure
onready var server_ip_address = $MultiplayerConfigure/ServerIP

onready var device_ip_address = $MultiplayerConfigure/DeviceIP

var game_template = preload("res://Level.tscn")

func _ready() -> void:
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_to_server")
	
	$MultiplayerConfigure/PlayerCount.hide()
	$MultiplayerConfigure/StartGame.hide()
	$Text.hide()
#	$MultiplayerConfigure/StartGame.disabled = true
	
	device_ip_address.text = Network.ip_address

func _player_connected(id) -> void:
	Network.player_count += 1
	$MultiplayerConfigure/PlayerCount.bbcode_text = "[center][color=green]Number of players: %s[/color][/center]" % str(Network.player_count)
	print("Player " + str(id) + " has connected")
	
func _player_disconnected(id) -> void:
	Network.player_count -= 1
	$MultiplayerConfigure/PlayerCount.bbcode_text = "[center][color=green]Number of players: %s[/color][/center]" % str(Network.player_count)
	print("Player " + str(id) + " has disconnected")
	
func instance_player(id):
#	var player_game = game_template.instance()
#	Players.add_child(player_game)
#	player_game.name = str(id)
#	player_game.set_network_master(id)
	pass
	

func _on_CreateServer_pressed():
	$MultiplayerConfigure/Or.hide()
	$MultiplayerConfigure/JoinServer.hide()
	$MultiplayerConfigure/CreateServer.hide()
	$MultiplayerConfigure/PlayerCount.show()
	$MultiplayerConfigure/StartGame.show()
	$MultiplayerConfigure/ServerIP.hide()
	
	Network.create_server()
	instance_player(get_tree().get_network_unique_id())
	$MultiplayerConfigure/PlayerCount.bbcode_text = "[center][color=green]Number of players: %s[/color][/center]" % str(Network.player_count)

func _on_JoinServer_pressed():
	if server_ip_address.text != "":
		multiplayer_config_ui.hide()
		$Text.show()
		Network.ip_address = server_ip_address.text
		Network.join_server()
		print("Joined Server")
	else:
		print("Server IP Address Invalid")

remote func game_starting(peers):
	# loads a copy of the game on each device
	print("Trying to load game from server")
	multiplayer_config_ui.hide()
	$Text.hide()
	var my_id = get_tree().get_network_unique_id()
	var player_game = game_template.instance()
	self.add_child(player_game)
	player_game.id = str(my_id)
	#player_game.set_network_master(my_id)
	var pos = peers.find(my_id)
	player_game.load_client(peers)
	
	print("All peers " + str(peers))
	print("Me: " + str(my_id))
	print("Sucessfully loaded game. I am player " + str(pos))

func _on_StartGame_pressed():
	print("LET'S GET READY TO PARTY!")
	multiplayer_config_ui.hide()
	$Text.hide()
	var my_id = get_tree().get_network_unique_id()
	var player_game = game_template.instance()
#	Players.add_child(player_game)
	player_game.id = str(my_id)
	#player_game.set_network_master(my_id)
	self.add_child(player_game)
	
	var peers = Array(get_tree().get_network_connected_peers())
	peers.insert(0, 1)
	print("All peers " + str(peers))
	print("Me: " + str(my_id))
	var pos = peers.find(my_id)
	player_game.load_server(peers)
	print("I am player " + str(pos))
	
	print("Sucessfully loaded game on server")
	
	rpc("game_starting", peers)
