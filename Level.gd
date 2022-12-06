# This file contains the main code for initializing the world and managing
# player communication.
#
# Contents:
# Setup
#   load_server
#   load_client
# RPC Calls
#   try_move
#   set_new_pos
#   try_shoot_gun
#   shoot_gun
#   try_animate
#   set_new_animation

extends Spatial

var id
var players = []
var my_peers = []
var player_template = preload("res://Player.tscn")
var bullet = preload("res://Bullet.tscn")
var is_server = false
var my_person
var my_pos

var _timer = null

remote func load_server(peers):
	my_peers = peers
	is_server = true
	for i in range(peers.size()):
		var player = player_template.instance()
		player.id = peers[i]
		add_child(player)
		players.append(player)
		player.show()
		player.global_transform.origin.x = 1 * i
		player.set_network_master(peers[i])
		if peers[i] == 1:
			my_person = player
			my_pos = player.global_transform.origin
			player.name = "Server"
			player.local_control = true
			#print("Setting camera!")
			#get_node("/root/NetworkSetup/Spatial/Server/SpringArm/Camera").make_current()
			#$Server/SpringArm/Camera.make_current()
		else:
			player.set_color_black()
	get_node("/root/NetworkSetup/Spatial/Server/SpringArm/Camera").make_current()

func load_client(peers):
	my_peers = peers
	for i in range(peers.size()):
		var player = player_template.instance()
		player.id = peers[i]
		add_child(player)
		players.append(player)
		player.show()
		player.global_transform.origin.x = 1 * i
		player.set_network_master(peers[i])
		if peers[i] == get_tree().get_network_unique_id():
			# this is me!
			my_person = player
			my_pos = player.global_transform.origin
			player.name = "Me"
			player.local_control = true
			#get_node(str(i) + "/SpringArm/Camera").make_current()
			#print("Loading client camera: " + str(peers[i]))
			#/$Me/SpringArm/Camera.make_current()
		if (peers[i] != 1):
			player.set_color_black()
	get_node("/root/NetworkSetup/Spatial/Me/SpringArm/Camera").make_current()
	

remotesync func try_move(peer, pos):
	# validate here
	var isValid = true
	
	if is_server:
		rpc("set_new_pos", peer, pos, isValid)

remotesync func set_new_pos(peer, pos, isValid):

	if peer != get_tree().get_network_unique_id():
		var player = players[my_peers.find(peer)]
		player.old_position.x = player.new_position.x
		player.old_position.y = player.new_position.y
		player.old_position.z = player.new_position.z
#		player.global_transform.origin.x = pos[0]
#		player.global_transform.origin.y = pos[1]
#		player.global_transform.origin.z = pos[2]
#		player._model.rotation.y = pos[3]
		player.potential_rotation = pos[3]
#		player._velocity = pos[4]
		player.new_position.x = pos[0]
		player.new_position.y = pos[1]
		player.new_position.z = pos[2]
		# player._model.rotation.y = pos[3]
		player.old_rotation = player.rotation.y
		player._velocity = player.new_velocity
		player.new_velocity = pos[4]
		player.time_since_last_update = 0
	
	if !isValid and peer == get_tree().get_network_unique_id():
		print("You are in an illegal position.")

remotesync func try_shoot_gun(peer, location):
	if is_server:
		print("Server detects shooting from " + str(location))
		rpc("shoot_gun", location)

remotesync func shoot_gun(location):
	var b = bullet.instance()
	add_child(b)
	b.global_transform = location
	b.velocity = b.transform.basis.z * b.muzzle_velocity
	
remotesync func try_animate(peer, animation):
	# validate here
	var isValid = true
	
	if is_server:
		rpc("set_new_animation", peer, animation, isValid)

remotesync func set_new_animation(peer, animation, isValid):

	if peer != get_tree().get_network_unique_id():
		var player = players[my_peers.find(peer)]
		player.play_animation(animation)
	
	if !isValid and peer == get_tree().get_network_unique_id():
		print("You are doing an illegal animation.")

func _process(delta):
	#if (my_person.global_transform.origin - my_pos).length_squared() > Vector3(.1, .1, .1).length_squared():
#	if my_person.global_transform.origin != my_pos:
#		my_pos = my_person.global_transform.origin
#		var rotation = my_person._model.rotation.y
#		rpc("try_move", get_tree().get_network_unique_id(), [my_pos.x, my_pos.y, my_pos.z, rotation])
#	if my_person.shoot:
#		my_person.shoot = false
#		rpc("try_shoot_gun", get_tree().get_network_unique_id(), my_person.muzzle_location)
#	if my_person.animation_changed:
#		rpc("try_animate", get_tree().get_network_unique_id(), my_person.current_animation)
	pass

func _on_Timer_timeout():
#	if my_person.global_transform.origin != my_pos:
	my_pos = my_person.global_transform.origin
	var rotation = my_person._model.rotation.y
	var velocity = my_person._velocity
	rpc("try_move", get_tree().get_network_unique_id(), [my_pos.x, my_pos.y, my_pos.z, rotation, velocity])
	if my_person.shoot:
		my_person.shoot = false
		rpc("try_shoot_gun", get_tree().get_network_unique_id(), my_person.muzzle_location)
	if my_person.animation_changed:
		rpc("try_animate", get_tree().get_network_unique_id(), my_person.current_animation)

func _ready():
	_timer = Timer.new()
	add_child(_timer)
	
	_timer.connect("timeout", self, "_on_Timer_timeout")
	_timer.set_wait_time(0.5)
	_timer.set_one_shot(false) # Make sure it loops
	_timer.start()
