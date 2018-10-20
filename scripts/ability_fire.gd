extends Area2D

var finished = false

func _on_bullet_body_enter( body ):
	if body.has_method("hit_by_bullet"):
		body.call("hit_by_bullet")

func _process(delta):
	if not Input.is_action_pressed("ability") and not finished:
		$anim.play("shutdown")
		finished = true
