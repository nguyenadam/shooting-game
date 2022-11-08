extends KinematicBody

export var speed:float = 3.0
export var jump_force:float = 16.0
export var gravity:float = 50.0
export(NodePath) onready var _spring_arm = $SpringArm as SpringArm

var new_velocity := Vector3.ZERO
var new_position := Vector3.ZERO
var old_position := Vector3.ZERO
var time_since_last_update := 0.0

var _velocity := Vector3.ZERO
var _snap_vector := Vector3.DOWN
var is_in_jump := false

var animation_changed:bool = false
var current_animation:String

var id
var local_control = false

export (PackedScene) var Bullet

onready var _model := $Robot as Spatial

var shoot = false
var muzzle_location

func _physics_process(delta:float)->void:
	if is_network_master():
		var animation:String
		var movement_input:bool = false
		var move_direction := Vector3.ZERO
		if local_control:
			move_direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
			move_direction.z = Input.get_action_strength("back") - Input.get_action_strength("forward")
			if move_direction != Vector3.ZERO:
				movement_input = true
		move_direction = move_direction.rotated(Vector3.UP, _spring_arm.rotation.y).normalized()
		
		_velocity.x = move_direction.x * speed
		_velocity.z = move_direction.z * speed
		_velocity.y -= gravity * delta
		
		var just_landed := is_on_floor() and _snap_vector == Vector3.ZERO
		if just_landed:
			is_in_jump = false
		var is_jumping := is_on_floor() and Input.is_action_just_pressed("jump")
		
		if is_jumping:
			if local_control:
				_velocity.y = jump_force
				_snap_vector = Vector3.ZERO
			is_in_jump = true
				
		elif just_landed:
			_snap_vector = Vector3.DOWN
		
		if Vector2(_velocity.z, _velocity.x).length() > 0.2:
			var look_direction = Vector2(_velocity.z, _velocity.x)
			_model.rotation.y = look_direction.angle()
		
		

		_velocity = move_and_slide_with_snap(_velocity, _snap_vector, Vector3.UP, true)
		
		# determine animation
		if local_control:
			if is_in_jump and movement_input:
				animation = "Robot_WalkJump"
			elif is_in_jump:
				animation = "Robot_Jump"
				print("IS JUMPING!")
			elif movement_input:
				animation = "Robot_Running"
			else:
				animation = "Robot_Idle"
			
			$Robot/AnimationPlayer.play(animation)
			if animation != current_animation:
				current_animation = animation
				animation_changed = true
			
	else:
		# just fall down
		_velocity.y -= gravity * delta
		_snap_vector = Vector3.DOWN
		
		time_since_last_update += delta
		var percentage_complete = time_since_last_update / 0.5
		var blended_velocity:Vector3 = _velocity + ((new_velocity - _velocity) * percentage_complete)
		var projection1 = old_position + blended_velocity * time_since_last_update
		var projection2 = new_position + new_velocity * time_since_last_update
		var interpolated_position = projection1 + (projection2 - projection1) * percentage_complete
		
		var move_vector = interpolated_position - global_transform.origin
		
		move_and_slide_with_snap(move_vector, _snap_vector, Vector3.UP, true)
	pass

func play_animation(animation):
	$Robot/AnimationPlayer.play(animation)

func set_color_black():
	var parts = $Robot/RobotArmature/Skeleton.get_children()
	for part in parts:
		part.set_surface_material(0, load("res://Assets/Animated-3D-Robot-9b67ca7ac428366c56e5466622d3557588809ca8/Better Collada (Godot)/Black.material"))
	$Robot/RobotArmature/Skeleton/Torso.set_surface_material(0, load("res://Assets/Animated-3D-Robot-9b67ca7ac428366c56e5466622d3557588809ca8/Better Collada (Godot)/Black.material"))
	$Robot/RobotArmature/Skeleton/Torso.set_surface_material(0, load("res://Assets/Animated-3D-Robot-9b67ca7ac428366c56e5466622d3557588809ca8/Better Collada (Godot)/Black.material"))

func _process(_delta)->void: 
	if _spring_arm != null:
		_spring_arm.translation = translation
	pass

	if is_network_master() and Input.is_action_just_pressed("shoot"):
		muzzle_location = $Robot/Gun/Muzzle.global_transform
		shoot = true
#		var b = Bullet.instance()
#		self.add_child(b)
#		b.global_transform = $Robot/Gun/Muzzle.global_transform
#		b.velocity = b.transform.basis.z * b.muzzle_velocity
