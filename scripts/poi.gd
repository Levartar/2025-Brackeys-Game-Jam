extends Node2D

enum PoiState {Initial, Preparing, Ready, Rescued, Burnt}

@export var char_sprite: Sprite2D
@export var prep_time: float = 10.0

var state: PoiState = PoiState.Initial
var secs_since_prep: float = 0.0
var prep_countdown: TextureProgressBar
var hut_sprite: Sprite2D # TODO: replace

var flight_sim: Node2D
var terrain: Control

func _ready() -> void:
  flight_sim = get_parent()
  terrain = get_parent().get_node("Terrain")
  hut_sprite = $Sprite2D
  prep_countdown = $TextureProgressBar
  prep_countdown.max_value = prep_time
  prep_countdown.value = prep_time
  prep_countdown.visible = false
  # print("State:", state) # test

func _process(delta: float) -> void:
  if state != PoiState.Rescued and state != PoiState.Burnt:
    if state == PoiState.Preparing:
      secs_since_prep += delta
      prep_countdown.value = prep_time - secs_since_prep
      if secs_since_prep >= prep_time:
        state = PoiState.Ready
        # print("State:", state) # test
    if terrain.is_position_on_fire(global_position):
      state = PoiState.Burnt
      # print("State:", state) # test
      prep_countdown.visible = false
      if hut_sprite: hut_sprite.modulate = Color(0.2, 0.2, 0.2, 1.0) # TODO: replace

func activate() -> void:
  if not flight_sim.get_is_any_poi_waiting():
    state = PoiState.Preparing
    # print("State:", state) # test
    prep_countdown.visible = true
    flight_sim.set_is_any_poi_waiting(true)
  else:
    print("Rescue the others waiting first!")

func rescue() -> void:
  state = PoiState.Rescued
  # print("State:", state) # test
  prep_countdown.visible = false
  if hut_sprite: hut_sprite.modulate = Color(0.7, 0.7, 0.7, 1.0)
  flight_sim.set_is_any_poi_waiting(false)

func _on_body_entered(body: Node2D) -> void:
  if body.name == "Plane":
    if state == PoiState.Initial:
      body.poi_interact = activate
    elif state == PoiState.Ready:
      body.poi_interact = rescue
    body.is_over_poi = true
    
func _on_body_exited(body: Node2D) -> void:
  if body.name == "Plane":
    body.is_over_poi = false
