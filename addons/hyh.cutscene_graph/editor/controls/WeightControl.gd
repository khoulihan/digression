@tool
extends MarginContainer


const Logging = preload("../../utility/Logging.gd")
var Logger = Logging.new("Cutscene Graph Editor", Logging.CGE_EDITOR_LOG_LEVEL)


@onready var SetWeightButton: LinkButton = $SetWeightButton
@onready var Weight: HBoxContainer = $Weight
@onready var WeightSpinBox: SpinBox = $Weight/WeightSpinBox


signal changed(weight: int)
signal cleared()


func configure_for_weight(weight: int) -> void:
	SetWeightButton.visible = weight < 1
	Weight.visible = weight >= 1
	WeightSpinBox.value = weight


func _on_weight_spin_box_value_changed(value: float) -> void:
	changed.emit(value)


func _on_clear_button_pressed() -> void:
	SetWeightButton.visible = true
	Weight.visible = false
	cleared.emit()


func _on_set_weight_button_pressed():
	print("setting weight to 1")
	configure_for_weight(1)
	changed.emit(1)
