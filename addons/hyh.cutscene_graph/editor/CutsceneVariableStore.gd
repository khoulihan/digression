@tool
extends Node


# Exported so that a set of default values can be set.
@export var store_data: Dictionary


func get_variable(variable_name):
	return store_data.get(variable_name)


func set_variable(variable_name, value):
	store_data[variable_name] = value


func clear():
	store_data.clear()
