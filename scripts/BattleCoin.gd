extends Area3D

# -----------------------------------------------
# BATTLE COIN
# Dropped by enemies when they die.
# Clones walk over them to collect automatically.
# Coins are tracked in Battlefield and shown on HUD.
# -----------------------------------------------

var value: int = 1
var _lifetime: float = 12.0   # Disappears after 12 seconds

func _ready():
	add_to_group("coins")

	# Gold coin mesh (stored so we can fade it out later)
	var mesh = MeshInstance3D.new()
	mesh.mesh = CylinderMesh.new()
	mesh.mesh.top_radius    = 0.18
	mesh.mesh.bottom_radius = 0.18
	mesh.mesh.height        = 0.06
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.45, 0.0)
	mat.roughness = 0.2
	mesh.set_surface_override_material(0, mat)
	add_child(mesh)

	# Add a collision shape so clones can pick it up
	var shape = CollisionShape3D.new()
	shape.shape = CylinderShape3D.new()
	shape.shape.radius = 0.3
	shape.shape.height = 0.2
	add_child(shape)

	# Spin slowly so it's easy to spot
	var tween = get_tree().create_tween().set_loops()
	tween.tween_property(mesh, "rotation:y", TAU, 1.5)

	# Connect pickup
	body_entered.connect(_on_body_entered)

	# Fade out and disappear after lifetime
	# (3D nodes don't have modulate — we animate the material colour alpha instead)
	await get_tree().create_timer(_lifetime - 2.0).timeout
	if not is_instance_valid(self):
		return
	var coin_mat = mesh.get_surface_override_material(0) as StandardMaterial3D
	if coin_mat:
		coin_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var fade = get_tree().create_tween()
		fade.tween_method(func(a: float): coin_mat.albedo_color.a = a, 1.0, 0.0, 2.0)
		fade.tween_callback(queue_free)
	else:
		await get_tree().create_timer(2.0).timeout
		queue_free()

func _on_body_entered(body):
	if body.is_in_group("clones"):
		# Tell the battlefield a coin was collected
		var bf = get_tree().get_first_node_in_group("battlefield")
		if bf and bf.has_method("collect_coin"):
			bf.collect_coin(value)
		SoundManager.play("click")
		queue_free()
