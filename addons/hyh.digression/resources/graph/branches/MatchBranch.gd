@tool
extends Resource
## Branch resource for "match" node branches.


## The node to proceed to if the value for this branch matches the variable.
@export var next: int = -1

## The value to match.
var value


# This is necessary to ensure that the value
# is saved to the resource
func _get_property_list():
	var properties = []
	properties.append({
		"name": "value",
		"type": null,
		"usage": PROPERTY_USAGE_STORAGE,
	})
	return properties
