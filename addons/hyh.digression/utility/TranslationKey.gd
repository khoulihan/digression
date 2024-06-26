@tool
extends RefCounted
## Helper class for functions related to translation keys.


const TR_KEY_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"


## Generates a random unique string to use as a translation key for text in a
## named graph.
static func generate(graph_name, type):
	var key = "%s_%s_%s" % [
		graph_name,
		type,
		_generate_random_string(randi_range(8, 16))
	]
	return key


static func _generate_random_string(length):
	var word = ""
	var chars = len(TR_KEY_CHARS)
	for i in range(length):
		word += TR_KEY_CHARS[randi() % chars]
	return word
