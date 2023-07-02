@tool
extends TextureRect


func set_warning(t):
	self.tooltip_text = t
	self.visible = true


func clear_warning():
	self.tooltip_text = ""
	self.visible = false
