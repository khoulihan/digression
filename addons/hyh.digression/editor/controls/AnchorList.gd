@tool
extends ItemList


signal anchor_selected(name)


var _anchor_list : Array[String]
var _current_filter : String = ""
var _filtered : Array[String]


func _ready() -> void:
	self.item_selected.connect(_on_item_selected)


func clear_list():
	_anchor_list = []
	self.clear()


func populate(anchors: Array) -> void:
	self.clear_list()
	_anchor_list.append_array(anchors)
	_anchor_list.sort()
	self.filter(_current_filter)


func select_anchor(name: String) -> void:
	self.deselect_all()
	if self.item_count == 0 or name == "":
		return
	for index in range(0, self.item_count):
		if self.get_item_text(index) == name:
			self.select(index)
			return


func select_first_anchor() -> void:
	if self.item_count > 0:
		self.select(0)
		_on_item_selected(0)


func filter(f: String) -> void:
	_filtered = []
	_current_filter = f
	if f == "":
		_filtered.append_array(_anchor_list)
	else:
		for a in _anchor_list:
			if a.containsn(f):
				_filtered.append(a)
	
	self.clear()
	for anchor in _filtered:
		self.add_item(anchor)


func _on_item_selected(index: int) -> void:
	anchor_selected.emit(self.get_item_text(index))
