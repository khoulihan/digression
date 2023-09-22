@tool
extends Resource

const Highlighting = preload("../../../../utility/Highlighting.gd")

func get_highlighted_syntax() -> String:
	return ""

func custom_duplicate(subresources=false):
	return self.duplicate(subresources)
