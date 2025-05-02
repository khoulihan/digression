@tool
extends RefCounted
## Base class for promises, which allow awaiting for the outcome of some
## process that may have multiple completion signals.


enum PromiseState {
	PENDING,
	FULFILLED,
	REJECTED,
}


signal completed(state: PromiseState, value: Variant)


var state: PromiseState
var value: Variant


func _init():
	state = PromiseState.PENDING


func _resolved(value: Variant = null) -> void:
	state = PromiseState.FULFILLED
	self.value = value
	completed.emit(state)


func _rejected(error: Variant = null) -> void:
	state = PromiseState.REJECTED
	self.value = error
	completed.emit(state)
