@tool
extends "ConditionBase.gd"

enum BooleanType {
	BOOLEAN_AND,
	BOOLEAN_OR
}

@export var operator: BooleanType
@export var children: Array


# I don't think it would be possible to implement an `evaluate` method here
# because would need to retrieve the variable value for each `ValueConditional`
# descendant, and I think that will probably be better handled by the
# `CutsceneController`

func get_highlighted_syntax() -> String:
	var components = []
	for child in children:
		# Not sure how to check if this is an instance of THIS class...
		# Since the children should only be BooleanCondition or ValueCondition
		# I think this is ok.
		if "operator" in child:
			# Boolean child - surround it in brackets
			components.append(
				"%s%s%s" % [
					Highlighting.highlight("(", Highlighting.SYMBOL_COLOUR),
					child.get_highlighted_syntax(),
					Highlighting.highlight(")", Highlighting.SYMBOL_COLOUR),
				]
			)
		else:
			components.append(child.get_highlighted_syntax())
			
	if operator == BooleanType.BOOLEAN_AND:
		return Highlighting.highlight(
			" and ",
			Highlighting.KEYWORD_COLOUR
		).join(components)
	return Highlighting.highlight(
			" or ",
			Highlighting.KEYWORD_COLOUR
		).join(components)
