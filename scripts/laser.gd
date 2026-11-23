extends Node2D
## Tembakan laser dari paddle.


func _draw() -> void:
	draw_rect(Rect2(-4, -12, 8, 24), Color(1.0, 0.2, 0.3, 0.3))
	draw_rect(Rect2(-1.5, -10, 3, 20), Color(1.0, 0.8, 0.85, 1.0))
