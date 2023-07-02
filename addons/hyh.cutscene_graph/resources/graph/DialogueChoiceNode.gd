@tool
extends "GraphNodeBase.gd"


const ChoiceBranch = preload("branches/ChoiceBranch.gd")


# This array no longer needs to allow nulls
@export var choices: Array[ChoiceBranch]
