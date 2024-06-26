@tool
extends RefCounted
## Helper class with code related to resources.


## Determines if a resource is embedded or if it had been saved to disk.
static func is_embedded(res):
	if res == null:
		return false
	return _resource_path_is_embedded(
		res.resource_path
	)


static func _resource_path_is_embedded(res_path):
	if res_path == null:
		return false
	return res_path.is_empty() or res_path.contains("::")
