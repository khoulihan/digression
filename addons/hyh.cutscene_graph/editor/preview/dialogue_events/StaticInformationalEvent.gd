@tool
extends MarginContainer
## Displays the details of an event in the graph previewer.


## Populate the control with the details of the event.
func populate(value, warning=null):
	$HB/Label.text = value
	if warning != null:
		$HB/ValidationWarning.set_warning(warning)
	else:
		$HB/ValidationWarning.clear_warning()
