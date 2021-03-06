# Default node type for a mob with basic attack pattern.
extends KinematicBody2D

var state = IdleState.new(self)

export(NodePath) onready var animation = $AnimationPlayer
export(NodePath) onready var timer = $DisengageTimer

const STATE_IDLE = 'idle'
const STATE_AGGROED = 'aggroed'
const STATE_ATTACKING = 'attacking'
const STATE_DISENGAGING = 'disengaging'
const STATE_MOVING = 'moving'
const STATE_SLEEPING = 'sleeping'

# Amount of damage the player suffers for each successful attack from this mob
const DAMAGE = 1

# Amount of seconds the mob will wait after disengaging before attacking the player again
const DISENGAGE_WAIT_TIME = 2

# Target to move to when aggroed
export(Vector2) onready var target = get_node('../Traveler')

# Point to fall back to when disengaging. No effect if set to 0/0.
const FALLBACK_OFFSET = Vector2(0, 0)

# Movement properties
export(Vector2) var velocity = Vector2()

const GRAVITY = 200.0
const SPEED = 250

export(bool) var playerInRange = false

func _ready():
	$MobHitArea.connect('area_entered', self, '_on_hit')
	$MobHitArea.connect('area_exited', self, '_on_hit_exit')
	$MobAggroRange.connect('area_entered', self, '_on_aggro')
	animation.connect('animation_finished', self, '_on_anim_finished')

	timer.wait_time = DISENGAGE_WAIT_TIME
	timer.connect('timeout', self, '_on_disengage_timeout')

func _physics_process(delta):
	if GRAVITY:
		velocity.y += delta * GRAVITY
		move_and_collide(velocity * delta)

	$AnimatedSprite.flip_h = velocity.x <= 0
	state.process(delta)

func _on_disengage_timeout():
	set_state(STATE_AGGROED)

func _on_aggro(area):
	if area.name == 'PlayerAggroRange' and get_state() == STATE_IDLE:
		set_state(STATE_AGGROED)

func _on_anim_finished(anim):
	if anim == 'attacking':
		if playerInRange:
			PlayerState.damage_player(DAMAGE)
		set_state(STATE_DISENGAGING)

func _on_hit(area):
	if area.name == 'PlayerHitbox':
		playerInRange = true
		if get_state() == STATE_AGGROED:
			set_state(STATE_ATTACKING)

	if area.name == 'PlayerShotHitArea':
		queue_free()

func _on_hit_exit(area):
	if area.name == 'PlayerHitbox' and get_state() == STATE_ATTACKING:
		playerInRange = false
		set_state(STATE_DISENGAGING)

func set_state(new_state):
	state.exit()

	match new_state:
		STATE_MOVING:
			state = MovingState.new(self)
		STATE_AGGROED:
			state = AggroedState.new(self)
		STATE_ATTACKING:
			state = AttackingState.new(self)
		STATE_DISENGAGING:
			state = DisengagingState.new(self)
		STATE_SLEEPING:
			state = SleepingState.new(self)
		_:
			state = IdleState.new(self)

	print('New state is ' + new_state)

func get_state():
	if state is AggroedState:
		return STATE_AGGROED
	if state is AttackingState:
		return STATE_ATTACKING
	if state is DisengagingState:
		return STATE_DISENGAGING
	if state is MovingState:
		return STATE_MOVING
	if state is SleepingState:
		return STATE_SLEEPING

	return STATE_IDLE

class IdleState:
	var mob

	func _init(mob):
		self.mob = mob

	func process(delta):
		mob.animation.queue('idle')

	func exit():
		mob.animation.clear_queue()

class MovingState:
	var mob

	func _init(mob):
		self.mob = mob
		mob.animation.play('moving')

	func process(delta):
		pass

	func exit():
		pass

class AggroedState extends MovingState:
	func _init(mob).(mob):
		pass

	func process(delta):
		.process(delta)
		mob.velocity = (mob.target.position - mob.position).normalized() * mob.SPEED

		if (mob.target.position - mob.position).length() > 5:
			mob.move_and_collide(mob.velocity * delta)

	func exit():
		pass

class DisengagingState extends MovingState:
	var fallback_point = Vector2()

	func _init(mob).(mob):
		fallback_point = mob.global_position + mob.FALLBACK_OFFSET

	func process(delta):
		.process(delta)

		if mob.global_position <= fallback_point:
			mob.velocity = (fallback_point.normalized() * mob.SPEED)
			mob.move_and_collide(mob.velocity * delta)
		else:
			mob.set_state(mob.STATE_IDLE)
			mob.timer.start()

	func exit():
		pass

class AttackingState:
	var mob

	func _init(mob):
		self.mob = mob
		mob.animation.play('attacking')

	func process(delta):
		pass

	func exit():
		pass

class SleepingState:
	var mob

	func _init(mob):
		self.mob = mob

	func process(delta):
		mob.animation.queue('sleeping')

	func exit():
		mob.animation.clear_queue()
