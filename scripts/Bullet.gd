extends Area3D

# -----------------------------------------------
# BULLET
# A bullet flies forward and disappears when it
# hits an enemy (or a clone if fired by an enemy).
# -----------------------------------------------

var speed: float = 25.0       # How fast the bullet travels
var damage: float = 25.0      # How much damage it deals on hit
var direction: Vector3        # Which way is it flying?
var fired_by: String = ""     # "clones" or "enemies" — stops friendly fire!
var lifetime: float = 3.0     # Bullet disappears after 3 seconds if it hits nothing

func _ready():
	# Connect the "body entered" signal so we know when we hit something
	body_entered.connect(_on_body_entered)

	# Self-destruct after lifetime seconds so bullets don't pile up forever
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _process(delta):
	# Move the bullet forward every frame
	position += direction * speed * delta

func _on_body_entered(body):
	# Did we hit an enemy? (bullet fired by a clone)
	if fired_by == "clones" and body.is_in_group("enemies"):
		body.take_damage(damage)
		queue_free()   # Bullet disappears on hit

	# Did we hit a clone? (bullet fired by an enemy)
	elif fired_by == "enemies" and body.is_in_group("clones"):
		body.take_damage(damage)
		queue_free()
