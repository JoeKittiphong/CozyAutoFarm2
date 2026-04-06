extends "res://entities/animals/farm_animal.gd"
class_name Chicken

const GameData = preload("res://systems/core/game_data.gd")

func _init() -> void:
	animal_type = GameData.ANIMAL_CHICKEN
