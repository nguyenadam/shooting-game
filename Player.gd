extends KinematicBody

export var speed:float = 3.0
export var jump_force:float = 10.0
export var gravity:float = 50.0
export(NodePath) onready var _spring_arm = $SpringArm as SpringArm

var _velocity := Vector3.ZERO
var _snap_vector := Vector3.DOWN

var id
var local_control = false

export (PackedScene) var Bullet

onready var _model := $Robot as Spatial

var shoot = false
var muzzle_location

func _physics_process(delta:float)->void:
	if is_network_master():
		var move_direction := Vector3.ZERO
		if local_control:
			move_direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
			move_direction.z = Input.get_action_strength("back") - Input.get_action_strength("forward")
		move_direction = move_direction.rotated(Vector3.UP, _spring_arm.rotation.y).normalized()
		
		_velocity.x = move_direction.x * speed
		_velocity.z = move_direction.z * speed
		_velocity.y -= gravity * delta
		
		var just_landed := is_on_floor() and _snap_vector == Vector3.ZERO
		var is_jumping := is_on_floor() and Input.is_action_just_pressed("jump")
		
		if is_jumping:
			if local_control:
				_velocity.y = jump_force
				_snap_vector = Vector3.ZERO
		elif just_landed:
			_snap_vector = Vector3.DOWN
		
		if Vector2(_velocity.z, _velocity.x).length() > 0.2:
			var look_direction = Vector2(_velocity.z, _velocity.x)
			_model.rotation.y = look_direction.angle()

		_velocity = move_and_slide_with_snap(_velocity, _snap_vector, Vector3.UP, true)
			
	else:
		# just fall down
		_velocity.y -= gravity * delta
		_snap_vector = Vector3.DOWN
		_velocity = move_and_slide_with_snap(_velocity, _snap_vector, Vector3.UP, true)
	pass

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
