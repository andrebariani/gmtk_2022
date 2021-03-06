extends KinematicBody2D

onready var Player = PlayerReference.get_player()
onready var collision_shape = $CollisionShape2D.shape
onready var knockback_timer = $Knockback_timer
onready var sprite = $Sprite
var animation_name = "GOING_DOWN"

export(PackedScene) var dust
export(PackedScene) var explosion

export (float) var speed
export (bool) var protector
export (int) var color_number
enum {NORMAL, GOING_DOWN, KNOCKBACK, STOP, CHARGING, CHARGE}
var color
var movement_status = NORMAL
var protections = 0
var knockback_vector

var enemies_to_int = {Constants.MELEE:0, Constants.RANGED:1, 
	Constants.SUPPORT:2}

signal enemy_died(enemy)

func on_ready():
	pass

func on_process(_delta):
	pass

func _process(delta):
	on_process(delta)


func _ready():
	$AnimationPlayer.play(animation_name)
	movement_status = GOING_DOWN
	color = Constants.enemy_colors[color_number]
	set_highlighted_color(GlobalNode.current_color)
	on_ready()


func die():
	var instance = explosion.instance()
	get_parent().call_deferred("add_child", instance)
	instance.global_position = global_position
	emit_signal("enemy_died")
	queue_free()


func spawn_particles():
	for i in range(6):
		i *= 0.25
		i -= 1
		_spawn_particle(3, Vector2(sin(i), cos(i))*25)

func _spawn_particle(size, variation):
	var instance = dust.instance()
	get_parent().call_deferred("add_child", instance)
	instance.global_position = (global_position + variation)
	instance.scale = Vector2(size, size)


func verify_colision(space_state, width, height, angle, rotate):
	# Verifica se há ocorrerá colisão a frente (rotacionado em angle).
	# width e height estão relacionados ao retângulo de colisão que será criado para verificar
	# a colisão
	# Se ocorrer uma colisão, o retorno é true, caso contrário é false.
	
	var query = Physics2DShapeQueryParameters.new()
	query.collision_layer = 0b00000000001000000000
	var shape = RectangleShape2D.new()
	shape.extents = Vector2(width, height)
	query.set_shape(shape)
	query.transform = Transform2D(rotate + deg2rad(angle), global_position + Vector2(0, -height).rotated(rotation + deg2rad(angle)))
	# Transform2D(rotation + deg2rad(angle), global_position + Vector2(0, -height).rotated(rotation + deg2rad(angle)))
	return len(space_state.collide_shape(query, 1)) != 0

func get_angle_to_dodge_obstacles(width, height, rotate = rotation):
	# Tenta retornar um angulo para o desvio de obstaculos
	# Width e heigth estão relacionados aos retângulos de colisão que serão criados
	# para verificar obstaculos. Width deve ser da largura do inimigo e height
	# quanto maior for, o inimigo detectará antes o obstaculo
	var space_state = get_world_2d().direct_space_state
	
	if not verify_colision(space_state, width, height, 0, rotate):
		return 0
	
	for angle in range(5, 91, 5):
		if not verify_colision(space_state, width, height, angle, rotate):
			return angle
	
	for angle in range(-5, -91, -5):
		if not verify_colision(space_state, width, height, angle, rotate):
			return angle
	
	return 0


func _on_Knockback_timer_timeout():
	movement_status = NORMAL


func _on_AnimationPlayer_animation_finished(_anim_name):
	movement_status = NORMAL


func take_knockback(received_knockback_vector, knockback_time = 1):
	knockback_timer.start(knockback_time)
	movement_status = KNOCKBACK
	knockback_vector = received_knockback_vector


func set_highlighted_color(enemy_type):
	sprite.material.set_shader_param("color", enemies_to_int[enemy_type])


func _on_FallHitbox_area_entered(area):
	# matar inimigos que estavam embaixo dele durante o spawn
	if movement_status != GOING_DOWN:
		print(area.get_parent().name)
		if area.get_parent().has_method("die"):
			area.get_parent().die()
