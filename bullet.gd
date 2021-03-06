extends RigidBody2D

func _on_bullet_body_enter( body ):
	if body.has_method("hit_by_bullet"):
		body.call("hit_by_bullet")
	queue_free()

func _on_Timer_timeout():
	$anim.play("shutdown")

func _on_GravityTimer_timeout():
	self.gravity_scale = 0.25
	$Timer.start()
