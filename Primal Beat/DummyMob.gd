extends RigidBody2D

var attacking = false

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	$MobHitArea.connect('area_entered', self, 'hit')

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func hit(object):
	queue_free()