@tool
extends "res://addons/hyh.digression/editor/preview/dialogue_events/StaticInformationalEvent.gd"

signal back_button_pressed()


func _on_button_pressed() -> void:
	back_button_pressed.emit()
