extends Node2D

enum PoIState {Initial, Preparing, Ready, Rescued}

@export var char_sprite: Sprite2D
@export var prep_time: float = 10.0

var state: PoIState = PoIState.Initial
var secs_since_prep: float = 0.0
var prep_countdown: TextureProgressBar
var hut_sprite: Sprite2D # TODO: replace

func _ready() -> void:
  hut_sprite = $Sprite2D
  prep_countdown = $TextureProgressBar
  prep_countdown.max_value = prep_time
  prep_countdown.value = prep_time
  prep_countdown.visible = false
  # print("State:", state) # test

func _process(delta: float) -> void:
  if state != PoIState.Rescued:
    if state == PoIState.Preparing:
      secs_since_prep += delta
      prep_countdown.value = prep_time - secs_since_prep
      if secs_since_prep >= prep_time:
        state = PoIState.Ready
        # print("State:", state) # test

func activate() -> void:
  state = PoIState.Preparing
  # print("State:", state) # test
  prep_countdown.visible = true

func rescue() -> void:
  state = PoIState.Rescued
  # print("State:", state) # test
  prep_countdown.visible = false
  if hut_sprite: hut_sprite.modulate = Color(0.8, 0.8, 0.8, 1.0)

func _on_body_entered(body: Node2D) -> void:
  if body.name == "Plane":
    if state == PoIState.Initial:
      body.poi_interact = activate
    elif state == PoIState.Ready:
      body.poi_interact = rescue
    body.is_over_poi = true
    
func _on_body_exited(body: Node2D) -> void:
  if body.name == "Plane":
    body.is_over_poi = false
