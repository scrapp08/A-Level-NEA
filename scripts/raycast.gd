extends RayCast3D

@onready var wall_sprite = preload("res://objects/powerups/wall/wallsprite.tscn")


func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("action_ability"):
		if not get_child(0):
			var ws = wall_sprite.instantiate()
			add_child(ws)
		else:
			get_child(0).queue_free()
