extends Node2D

enum PoiState {Initial, Preparing, Ready, Rescued, Burnt}

@export var char_sprite: Sprite2D
@export var prep_time: float = 10.0

var state: PoiState = PoiState.Initial
var secs_since_prep: float = 0.0
var prep_countdown: TextureProgressBar
var hut_sprite: Sprite2D
var input_hint: Sprite2D

var flight_sim: Node2D
var terrain: Control
var plane: CharacterBody2D

func _ready() -> void:
  flight_sim = get_parent()
  terrain = flight_sim.get_node("Terrain")
  plane = flight_sim.get_node("Plane")
  hut_sprite = $Sprite2D
  input_hint = $InputHint
  prep_countdown = $TextureProgressBar
  prep_countdown.max_value = prep_time
  prep_countdown.value = prep_time
  prep_countdown.visible = false
  # print("State:", state) # test

func _process(delta: float) -> void:
  if state != PoiState.Rescued and state != PoiState.Burnt:
    if state == PoiState.Preparing:
      flight_sim.speech_bubble.text = "I'll grab my stuff!"
      secs_since_prep += delta
      prep_countdown.value = prep_time - secs_since_prep
      if secs_since_prep >= prep_time:
        state = PoiState.Ready
        flight_sim.speech_bubble.text = "Get me outta here!"
        # print("State:", state) # test
    if terrain.is_position_on_fire(global_position): # TODO: check why it's unreliable
      state = PoiState.Burnt
      # print("State:", state) # test
      prep_countdown.visible = false
      if hut_sprite: hut_sprite.modulate = Color(0.2, 0.2, 0.2, 1.0) # TODO: replace

func activate() -> void:
  if not flight_sim.get_is_any_poi_waiting() and not plane.has_passengers:
    input_hint.visible = false
    state = PoiState.Preparing
    # print("State:", state) # test
    prep_countdown.visible = true
    flight_sim.set_is_any_poi_waiting(true)
  else:
    print("Rescue the others waiting first!")

func rescue() -> void:
  input_hint.visible = false
  state = PoiState.Rescued
  # print("State:", state) # test
  flight_sim.speech_bubble.text = "Bring me to the airport!"
  plane.add_passengers()
  flight_sim.set_is_any_poi_waiting(false)
  prep_countdown.visible = false
  if hut_sprite: hut_sprite.modulate = Color(0.7, 0.7, 0.7, 1.0)

func _on_body_entered(body: Node2D) -> void:
  if body.name == "Plane":
    if state == PoiState.Initial and not flight_sim.get_is_any_poi_waiting() and not plane.has_passengers:
      input_hint.visible = true
      body.set_poi_interaction(activate)
    elif state == PoiState.Ready and not plane.has_passengers:
      input_hint.visible = true
      body.set_poi_interaction(rescue)
    body.set_is_over_poi(true)
    
func _on_body_exited(body: Node2D) -> void:
  if body.name == "Plane":
    input_hint.visible = false
    body.set_is_over_poi(false)
