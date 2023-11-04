@tool
extends GraphNode


func set_comment_and_size(comment, size):
	$Label.text = comment
	self.size = size
