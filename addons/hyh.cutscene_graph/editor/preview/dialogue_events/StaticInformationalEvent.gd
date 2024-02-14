@tool
extends MarginContainer


func populate(value, warning=null):
	$HB/Label.text = value
	if warning != null:
		$HB/ValidationWarning.set_warning(warning)
	else:
		$HB/ValidationWarning.clear_warning()
