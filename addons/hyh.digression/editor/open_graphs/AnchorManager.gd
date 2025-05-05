@tool
extends RefCounted


signal changed()


var anchors: Array[Anchor]

var _by_id: Dictionary[int, Anchor]
var _by_name: Dictionary[String, Anchor]


## Configure the manager for the provided graph.
func configure(graph: DigressionDialogueGraph) -> void:
	anchors = []
	var a := graph.get_anchors()
	for id in a:
		anchors.append(
			Anchor.new(
				id,
				a[id]
			)
		)
	_rebuild_maps()
	changed.emit()


## Clear the list of anchors.
func clear() -> void:
	anchors = []
	changed.emit()


## Get the anchor for the provided name.
func get_anchor_by_name(name: String) -> Anchor:
	return _by_name[name]


## Get the anchor for the provided id.
func get_anchor_by_id(id: int) -> Anchor:
	return _by_id[id]


# TODO: This is for populating nodes that take anchors a destinations.
# It would be preferable to return an id -> Anchor map.
## Get a map of anchor ids to names.
func get_anchor_map_by_id() -> Dictionary[int, String]:
	var m: Dictionary[int, String] = {}
	for id in _by_id:
		m[id] = _by_id[id].name
	return m


## Return a collection of the anchors matching the provided filter string.
func filter(f: String) -> Array[Anchor]:
	var filtered: Array[Anchor] = []
	if f == "":
		filtered.append_array(anchors)
	else:
		for a in anchors:
			if a.name.containsn(f):
				filtered.append(a)
	
	return filtered


## Rebuild the id -> Anchor and name -> Anchor mapping dictionaries.
func _rebuild_maps() -> void:
	_by_id = {}
	_by_name = {}
	for anchor in anchors:
		_by_id[anchor.id] = anchor
		_by_name[anchor.name] = anchor


## Represents an anchor in a DigressionDialogueGraph during graph editing
## i.e. this is not a Resource.
class Anchor extends RefCounted:
	var id: int
	var name: String
	
	func _init(id: int, name: String) -> void:
		self.id = id
		self.name = name
