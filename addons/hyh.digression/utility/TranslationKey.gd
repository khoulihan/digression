@tool
extends RefCounted
## Helper class for functions related to translation keys.


const TR_KEY_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
static var _tr_key_text_processing_regex := RegEx.create_from_string(r'[\w]*')

## Generates a random unique string to use as a translation key for text in a
## named graph.
static func generate(graph_name, type) ->  String:
	var key := "%s_%s_%s" % [
		graph_name,
		type,
		_generate_random_string(randi_range(8, 16))
	]
	return key


## Generate a translation key base on a section of dialogue.
static func generate_from_text(text: String) -> String:
	var processed_sections := _tr_key_text_processing_regex.search_all(
		text.strip_escapes()
	)
	
	var psp: Array[String] = []
	for section in processed_sections:
		var j := "_".join(section.strings)
		if not j.is_empty():
			psp.append(j)

	var processed := "_".join(psp)
	processed = processed.replace(" ", "_").to_upper().left(32).rstrip("_")
	var key = "%s_%s" % [
		processed,
		_generate_random_string(randi_range(8, 16))
	]
	return key


static func _generate_random_string(length):
	var word = ""
	var chars = len(TR_KEY_CHARS)
	for i in range(length):
		word += TR_KEY_CHARS[randi() % chars]
	return word
