@tool
extends Node
## Stores variables for use in dialogue graphs.

# Exported so that a set of default values can be set.
@export var store_data: Dictionary


## Get a variable from the store.
func get_variable(variable_name):
	return store_data.get(variable_name)


## Set the value of a variable in the store.
func set_variable(variable_name, value):
	store_data[variable_name] = value


## Check if the store contains the specified variable.
func has_variable(variable_name):
	return store_data.has(variable_name)


## Clear the store completely.
func clear():
	store_data.clear()
