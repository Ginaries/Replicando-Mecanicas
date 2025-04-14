extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var label: Label = $Player/Camera2D/Label


func _process(delta: float) -> void:
	label.text=str(int(player.velocity.x))
