class_name Weight extends Node

## What a thing weighs, for whatever counts weight: a pressure plate, a
## seesaw, a sinking platform. Mounted as a child named "Weight" on anything
## that presses down - Ivo, a released load, a crate, and his burned shadow,
## which weighs exactly what he does (design 02 section 7.1: "a sombra conta
## como o heroi estando ali").
##
## Units are Ivos: Ivo is 1.0, and a plate that needs "someone" needs 1.0.

const NODE_NAME := "Weight"

@export var mass := 1.0

## The Weight of `node` (a body or an area), or null when it weighs nothing.
static func of(node: Node) -> Weight:
	return node.get_node_or_null(NODE_NAME) as Weight
