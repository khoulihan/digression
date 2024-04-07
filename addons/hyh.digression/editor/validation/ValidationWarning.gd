@tool
extends TextureRect
## Control for displaying a validation warning to the user.


## Set the warning text.
func set_warning(t):
	self.tooltip_text = t
	self.visible = true


## Clear the warning.
func clear_warning():
	self.tooltip_text = ""
	self.visible = false
