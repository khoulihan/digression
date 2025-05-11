@tool
extends ItemList


signal anchor_selected(name: String)


const AnchorManager = preload("../../open_graphs/AnchorManager.gd")


var _manager: AnchorManager
var _current_filter : String = ""
var _filtered : Array[AnchorManager.Anchor]


func _ready() -> void:
	self.item_selected.connect(_on_item_selected)


## Configure the list for the provided AnchorManager.
func configure(manager: AnchorManager) -> void:
	_manager = manager
	_manager.changed.connect(_on_manager_changed)


## Clear the list.
func clear_list():
	self.clear()


## Select the anchor with the provided name.
func select_anchor(name: String) -> void:
	print("Hopefully selecting anchor %s" % name)
	self.deselect_all()
	if self.item_count == 0 or name == "":
		return
	for index in range(0, self.item_count):
		if self.get_item_text(index) == name:
			print("Selecting anchor index %s")
			self.select(index)
			return


## Select the first anchor in the list.
func select_first_anchor() -> void:
	if self.item_count > 0:
		self.select(0)
		_on_item_selected(0)


## Filter the list by name.
func filter(f: String) -> void:
	_current_filter = f
	_refresh()


func _refresh() -> void:
	_filtered = _manager.filter(_current_filter)
	
	self.clear()
	for anchor in _filtered:
		self.add_item(anchor.name)


func _on_manager_changed() -> void:
	_refresh()


func _on_item_selected(index: int) -> void:
	anchor_selected.emit(self.get_item_text(index))
