@tool
extends MarginContainer
## Control for allowing a weight to be assigned to a branch.


signal changed(weight: int)
signal cleared()

const Logging = preload("../../utility/Logging.gd")

var _logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)

@onready var _set_weight_button: LinkButton = $SetWeightButton
@onready var _weight: HBoxContainer = $Weight
@onready var _weight_spin_box: SpinBox = $Weight/WeightSpinBox


## Configure the control for the specified weight value.
## -1 means no explicit weight set, and the LinkButton will be displayed.
func configure_for_weight(weight: int) -> void:
	_set_weight_button.visible = weight < 1
	_weight.visible = weight >= 1
	_weight_spin_box.value = weight


func _on_weight_spin_box_value_changed(value: float) -> void:
	changed.emit(value)


func _on_clear_button_pressed() -> void:
	configure_for_weight(-1)
	cleared.emit()


func _on_set_weight_button_pressed():
	configure_for_weight(1)
	changed.emit(1)
