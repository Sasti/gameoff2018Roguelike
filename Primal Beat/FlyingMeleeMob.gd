# A flying enemy unaffected by gravity.
# Hovers in the air until the player enters its aggro range, then pursues the player.
# When it manages to reach the player's attack range, it latches on, slowly draining their life.
extends KinematicBody2D

# Whether the player has entered our aggro range
var aggroed = false

# Whether we are in range to attack the player
var attacking = false

# Where to move when aggroed
var target = Vector2()

# Movement parameters
var speed = 15
var velocity = Vector2()

func _ready():
	target = get_node('../Traveler')
	$MobHitArea.connect('area_entered', self, 'hit')
	$MobAggroRange.connect('area_entered', self, 'aggro')

func _physics_process(delta):
	velocity = (target.position - position).normalized() * speed

	if aggroed:
		move_and_collide(velocity)

func hit(area):
	if area.name == 'PlayerShotHitArea':
		print('mob hit by shot')
		queue_free()

func aggro(area):
	if area.name == 'PlayerAggroRange':
		print('mob aggroed')
		aggroed = true
