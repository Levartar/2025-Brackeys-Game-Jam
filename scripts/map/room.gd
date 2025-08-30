extends Node2D
class_name Room

enum Type {NOT_ASSIGNED, START, END, NORMAL, CAMPFIRE, EVENT, SHOP, TREASURE, BOSS}

@export var type: Type = Type.NOT_ASSIGNED