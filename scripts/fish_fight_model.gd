class_name FishFightModel
extends RefCounted

enum Phase { RECOVERY, SURGE_WINDUP, SURGE }
enum Outcome { ONGOING, LANDED, LINE_BREAK, THROWN_HOOK }

const DEFAULT_CONFIG := {
	"recovery_durations": [3.2, 3.0, 3.1, 3.0],
	"windup_durations": [1.15, 0.8, 0.75],
	"surge_durations": [1.35, 1.45, 1.35],
	"surge_count": 3,
	"danger_window": 0.9,
	"resolve_failures": false,
	"recovery_only": false,
	"recovery_reel_rate": 0.115,
}

var phase := Phase.RECOVERY
var outcome := Outcome.ONGOING
var tension := 0.48
var landing_progress := 0.0
var high_tension_danger := 0.0
var slack_danger := 0.0
var surge_count := 0

var _phase_elapsed := 0.0
var _surge_progress_floor := 0.0
var _config := DEFAULT_CONFIG.duplicate(true)


func start(configuration := {}) -> void:
	_config = DEFAULT_CONFIG.duplicate(true)
	for key in configuration:
		_config[key] = configuration[key]
	phase = Phase.RECOVERY
	outcome = Outcome.ONGOING
	tension = 0.48
	landing_progress = 0.0
	high_tension_danger = 0.0
	slack_danger = 0.0
	surge_count = 0
	_phase_elapsed = 0.0
	_surge_progress_floor = 0.0


func advance(delta: float, reel_held: bool) -> Dictionary:
	if outcome != Outcome.ONGOING or delta <= 0.0:
		return snapshot()

	_phase_elapsed += delta
	match phase:
		Phase.RECOVERY:
			if reel_held:
				tension = move_toward(tension, 0.56, delta * 0.42)
				landing_progress = minf(
					landing_progress + delta * float(_config["recovery_reel_rate"]),
					1.0
				)
			else:
				tension = move_toward(tension, 0.0, delta * 0.22)
		Phase.SURGE_WINDUP:
			tension = move_toward(tension, 0.62 if reel_held else 0.46, delta * 0.22)
		Phase.SURGE:
			if reel_held:
				tension = move_toward(tension, 1.0, delta * 0.72)
			else:
				tension = move_toward(tension, 0.52, delta * 0.62)
				landing_progress = maxf(_surge_progress_floor, landing_progress - delta * 0.035)

	_update_danger(delta)
	if outcome != Outcome.ONGOING:
		return snapshot()

	if landing_progress >= 1.0 and (
		bool(_config["recovery_only"]) or surge_count >= int(_config["surge_count"])
	):
		outcome = Outcome.LANDED
		return snapshot()

	_advance_phase_if_needed()
	return snapshot()


func snapshot() -> Dictionary:
	return {
		"phase": phase,
		"phase_name": phase_name(),
		"outcome": outcome,
		"outcome_name": outcome_name(),
		"tension": tension,
		"landing_progress": landing_progress,
		"high_tension_danger": high_tension_danger,
		"slack_danger": slack_danger,
		"surge_count": surge_count,
		"surge_progress_floor": _surge_progress_floor,
		"phase_duration": _get_phase_duration(),
		"resolve_failures": bool(_config["resolve_failures"]),
	}


func phase_name() -> String:
	return ["recovery", "surge wind-up", "surge"][phase]


func outcome_name() -> String:
	return ["ongoing", "landed", "line break", "thrown hook"][outcome]


func _get_phase_duration() -> float:
	match phase:
		Phase.RECOVERY:
			var durations: Array = _config["recovery_durations"]
			return float(durations[min(surge_count, durations.size() - 1)])
		Phase.SURGE_WINDUP:
			var durations: Array = _config["windup_durations"]
			return float(durations[min(surge_count, durations.size() - 1)])
		_:
			var durations: Array = _config["surge_durations"]
			return float(durations[min(surge_count, durations.size() - 1)])


func _update_danger(delta: float) -> void:
	if bool(_config["recovery_only"]):
		high_tension_danger = 0.0
		slack_danger = 0.0
		return
	var danger_window := float(_config["danger_window"])
	if tension >= 0.86:
		high_tension_danger += delta
	else:
		high_tension_danger = maxf(0.0, high_tension_danger - delta * 2.4)
	if tension <= 0.14:
		slack_danger += delta
	else:
		slack_danger = maxf(0.0, slack_danger - delta * 2.4)
	if bool(_config["resolve_failures"]) and high_tension_danger >= danger_window:
		outcome = Outcome.LINE_BREAK
	elif bool(_config["resolve_failures"]) and slack_danger >= danger_window:
		outcome = Outcome.THROWN_HOOK


func _advance_phase_if_needed() -> void:
	match phase:
		Phase.RECOVERY:
			if bool(_config["recovery_only"]):
				return
			if _phase_elapsed >= _get_phase_duration():
				if surge_count < int(_config["surge_count"]):
					_set_phase(Phase.SURGE_WINDUP)
				elif landing_progress < 1.0:
					_phase_elapsed = 0.0
		Phase.SURGE_WINDUP:
			if _phase_elapsed >= _get_phase_duration():
				_surge_progress_floor = maxf(0.0, landing_progress - 0.1)
				_set_phase(Phase.SURGE)
		Phase.SURGE:
			if _phase_elapsed >= _get_phase_duration():
				surge_count += 1
				_set_phase(Phase.RECOVERY)


func _set_phase(next_phase: Phase) -> void:
	phase = next_phase
	_phase_elapsed = 0.0
