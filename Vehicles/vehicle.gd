extends RigidBody2D

export var maxSpeed = 100
export var maxAcceleration = 100
export var angleSpeed = 0.1

const defaultDirection = Vector2(-1, 0)

var currentDirection

func _ready():
	$AnimatedSprite.play("default")
	currentDirection = defaultDirection

func _process(delta):
	#Ce bloc permet de contrôler l'accélération du véhicule sur les touches de direction
	"""	var vel = Vector2()
	if Input.is_action_pressed("ui_up"):
		vel.y = -maxAcceleration
	if Input.is_action_pressed("ui_down"):
		vel.y = maxAcceleration
	if Input.is_action_pressed("ui_left"):
		vel.x = -maxAcceleration
	if Input.is_action_pressed("ui_right"):
		vel.x = maxAcceleration
		
	self.applied_force = vel"""
	
	#Ce bloc permet de gérer un véhicule en utilisant les touches avant et arrière comme accélération/décélération
	#et les touches gauches et droites pour tourner le véhicule
	if Input.is_action_pressed("ui_up"):
		self.applied_force = maxAcceleration * currentDirection.normalized()
	elif Input.is_action_pressed("ui_down"):
		self.applied_force = -maxAcceleration * currentDirection.normalized()
	else:
		self.applied_force = Vector2.ZERO
	if Input.is_action_pressed("ui_left"):
		currentDirection = currentDirection.rotated(-angleSpeed)
		self.linear_velocity = self.linear_velocity.rotated(-angleSpeed)
	if Input.is_action_pressed("ui_right"):
		currentDirection = currentDirection.rotated(angleSpeed)
		self.linear_velocity = self.linear_velocity.rotated(angleSpeed)
	
	self.rotation = defaultDirection.angle_to(currentDirection)

