# Default node type for a mob with basic attack pattern.
extends KinematicBody2D

onready var state = IdleState.new(self)

export(NodePath) onready var animation = $AnimationPlayer

const STATE_IDLE = 'idle'
const STATE_AGGROED = 'aggroed'
const STATE_ATTACKING = 'attacking'
const STATE_DISENGAGING = 'disengaging'
const STATE_MOVING = 'moving'

# Amount of damage the player suffers for each successful attack from this mob
const DAMAGE = 1

# Amount of seconds the mob will wait after disengaging before attacking the player again
const DISENGAGE_WAIT_TIME = 2

# Target to move to when aggroed
export(Vector2) var target = Vector2()

# Point to fall back to when disengaging. No effect if set to 0/0.
const FALLBACK_OFFSET = Vector2(0, 0)

# Movement properties
export(Vector2) var velocity = Vector2()
const GRAVITY = 600
const SPEED = 250

func _ready():
	target = get_node('../Traveler')
	$MobHitArea.connect('area_entered', self, '_on_hit')
	$MobAggroRange.connect('area_entered', self, '_on_aggro')
	animation.connect('animation_finished', self, '_on_anim_finished')

	$DisengageTimer.wait_time = DISENGAGE_WAIT_TIME
	$DisengageTimer.connect('timeout', self, '_on_disengage_timeout')

func _physics_process(delta):
	$AnimatedSprite.flip_h = velocity.x <= 0
	state.process(delta)

func _on_disengage_timeout():
	set_state(STATE_AGGROED)

func _on_aggro(area):
	if area.name == 'PlayerAggroRange' and get_state() == STATE_IDLE:
		set_state(STATE_AGGROED)

func _on_anim_finished(anim):
	print('Animation finished: ' + anim)
	if anim == 'attacking':
		PlayerState.damage_player(DAMAGE)
		set_state(STATE_DISENGAGING)

func _on_hit(area):
	if area.name == 'PlayerHitbox' and get_state() == STATE_AGGROED:
		set_state(STATE_ATTACKING)

	if area.name == 'PlayerShotHitArea':
		queue_free()

func set_state(new_state):
	state.exit()

	if new_state == STATE_MOVING:
		state = MovingState.new(self)
	elif new_state == STATE_AGGROED:
		state = AggroedState.new(self)
	elif new_state == STATE_ATTACKING:
		state = AttackingState.new(self)
	elif new_state == STATE_DISENGAGING:
		state = DisengagingState.new(self)
	else:
		state = IdleState.new(self)

	print('New state is ' + new_state)

func get_state():
	if state is AggroedState:
		return STATE_AGGROED
	elif state is AttackingState:
		return STATE_ATTACKING
	elif state is DisengagingState:
		return STATE_DISENGAGING
	elif state is MovingState:
		return STATE_MOVING
	else:
		return STATE_IDLE

class IdleState:
	var mob

	func _init(mob):
		self.mob = mob

	func process(delta):
		mob.animation.queue('idle')

	func exit():
		pass

class MovingState:
	var mob

	func _init(mob):
		self.mob = mob

	func process(delta):
		mob.animation.play('moving')

	func exit():
		pass

class AggroedState extends MovingState:
	func _init(mob).(mob):
		pass

	func process(delta):
		.process(delta)

		mob.velocity = (mob.target.position - mob.position).normalized() * mob.SPEED
		mob.move_and_collide(mob.velocity * delta)

class DisengagingState extends MovingState:
	var collision
	var fallback_point = Vector2()

	func _init(mob).(mob):
		fallback_point = mob.global_position + mob.FALLBACK_OFFSET

	func process(delta):
		.process(delta)

		if collision == null:
			mob.velocity = fallback_point.normalized() * mob.SPEED
			collision = mob.move_and_collide(mob.velocity * delta)
		else:
			mob.set_state(mob.STATE_IDLE)
			mob.DisengageTimer.start()

class AttackingState:
	var mob

	func _init(mob):
		self.mob = mob

	func process(delta):
		mob.animation.play('attacking')
		print(mob.animation.current_animation_position)

	func exit():
		pass
