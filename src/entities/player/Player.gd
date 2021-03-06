extends KinematicBody2D
class_name Player

signal rolled()
signal took_damage()
signal health_changed(value)
signal enemy_hit()
signal enemy_killed()
signal advanced_combo(face)
signal triggered_combo()
signal died()

export var debug = false

export var MAX_HEALTH = 3
onready var health = MAX_HEALTH
var dead = false
export var INVINCIBLE_DURATION = 1

var current_speed = 100
export (int) var WALK_SPEED = 600
onready var walk_speed = WALK_SPEED
var ori: Vector2
var has_dir_control = true
var knockback = Vector2.ZERO

export (int) var ROLL_SPEED = 1200
export (int) var ROLL_FRAMES = 15
onready var roll_speed = ROLL_SPEED
var is_rolling = false

export (int) var CHARGE_SPEED = 3000
onready var charge_speed = CHARGE_SPEED
export var MAX_CHARGE = 0.75

export(PackedScene) var dust

var look_vector = Vector2.ZERO

onready var inputHelper = $Inputs
onready var stateMachine = $StateMachine
onready var dieFaces = $DieFaces
onready var hitbox = $Hitbox
onready var sprite = $Sprite
onready var light = $Sprite/Light2D

onready var _invincibleTimer = $InvincibleTimer
onready var _hurtbox = $Hurtbox
onready var _pointer = $Pointer
onready var _diceAnim : DiceAnimation = $Sprite/DiceAnimation
onready var _state_debug = $CanvasLayer/Debug/State
onready var _die_side_debug = $DieSide

onready var _light_behind = $Lights/Behind
onready var _light_front = $Lights/Front
onready var _light_left = $Lights/Left
onready var _light_right = $Lights/Right

onready var sfx_roll = $sfx/roll
onready var sfx_charge_load = $sfx/charge_load
onready var sfx_charge = $sfx/charge
onready var sfx_damage = $sfx/damage
onready var sfx_die = $sfx/die
onready var sfx_thud = $sfx/thud
onready var sfx_enemy_death = $sfx/enemy_die

onready var timers = {
	"roll": PlayerTimer.new(ROLL_FRAMES),
}

var enablers = {
	move = true,
	attack = true,
	shoot = true,
	roll = true,
	charge = true
}

var current_enemy_type = Constants.MELEE
var next_combo_face = 1
var load_amount = 0


func _ready():
	current_speed = walk_speed
	inputHelper.init(self)
	stateMachine.init(self)
	
	toggle_charge(true)
	
	if debug:
		$CanvasLayer/Debug.visible = true
		$DieSide.visible = true


func _physics_process(delta):
	look_vector = get_global_mouse_position() - global_position
	move_and_collide(knockback * delta)
	knockback = lerp(knockback, Vector2.ZERO, 0.1)
	
	update_timers()
	inputHelper.get_inputs()
	
	stateMachine.run(delta)
	
	if debug:
		_die_side_debug.set_text()
		_die_side_debug.set_text()
	
	if Input.is_action_just_pressed("ui_accept"):
		take_damage()


func apply_velocity(velocity):
	move_and_slide(current_speed * velocity)


func update_timers():
	for t in timers.values():
		t.tick()


func take_damage():
	if dead or _invincibleTimer.time_left > 0:
		return
	
	sfx_damage.play()
	sprite.blink_anim()
	set_invincible(INVINCIBLE_DURATION)
	emit_signal("took_damage")
	
	set_health(health - 1)
	if health <= 0:
		sfx_die.play()
		emit_signal("died")
		dead = true


func set_health(value):
	health = value
	emit_signal("health_changed", health)


func take_knockback(velocity):
	knockback += velocity
	

func get_input(key):
	return inputHelper.inputs[key]


func toggle_charge(value):
	enablers.charge = value
	if value:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		_pointer.visible = false
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		_pointer.frame = 0
		_pointer.visible = true


func spawn_particles(size, variation):
	var instance = dust.instance()
	get_parent().call_deferred("add_child", instance)
	instance.global_position = (global_position + 
		Vector2(rand_range(-variation, variation), 
			rand_range(-variation, variation)))
	instance.scale = Vector2(size, size)


func set_invincible(duration):
	_hurtbox.call_deferred("disabled", true)
	_invincibleTimer.start(duration)


func deactivate_invincible():
	sprite.stop_anim()
	_hurtbox.set_deferred("disabled", false)


func set_enabler(enabler, value):
	enablers[enabler] = value


func set_input_disabled(value):
	inputHelper.disabled = value


func setup_state_queue(state):
	_state_debug.set_text("%s <= %s" % [state, _state_debug.get_text()])

func approach(a, b, amount):
	if (a < b):
		a += amount
		if (a > b):
			return b
	else:
		a -= amount
		if(a < b):
			return b
	return a


func _on_Roll_rolled(direction):
	if direction == Constants.LEFT:
		dieFaces.roll_left()
	elif direction == Constants.RIGHT:
		dieFaces.roll_right()
	elif direction == Constants.BEHIND:
		dieFaces.roll_up()
	else:
		dieFaces.roll_down()
	
	_diceAnim.move_dice(direction, dieFaces.get_current_face(), 
		dieFaces.get_face(Constants.FRONT))
	current_enemy_type = dieFaces.get_current_enemy_type()
	_light_front.color = Constants.enemy_colors[dieFaces.get_enemy_type(Constants.FRONT)]
	_light_behind.color = Constants.enemy_colors[dieFaces.get_enemy_type(Constants.BEHIND)]
	_light_left.color = Constants.enemy_colors[dieFaces.get_enemy_type(Constants.LEFT)]
	_light_right.color = Constants.enemy_colors[dieFaces.get_enemy_type(Constants.RIGHT)]
	
	emit_signal("rolled", direction)


func _on_Charge_enemy_killed():
	toggle_charge(true)
	emit_signal("enemy_killed")
	set_invincible(INVINCIBLE_DURATION/2)
	
	if dieFaces.get_current_face() == next_combo_face:
		next_combo_face += 1
		if next_combo_face == 7:
			set_health(MAX_HEALTH)
			emit_signal("triggered_combo")
			next_combo_face = 1
	
	else:
		next_combo_face = 1
	
	sfx_enemy_death.play()
	emit_signal("advanced_combo", next_combo_face)


func _on_InvincibleTimer_timeout():
	deactivate_invincible()


func _on_Charge_enemy_hit():
	sfx_thud.play()
	emit_signal("enemy_hit")
