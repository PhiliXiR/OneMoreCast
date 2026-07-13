class_name FieldJournal
extends RefCounted

const MAX_OBSERVATIONS := 8

var observations: Array[Dictionary] = []


func record(kind: String, conditions: Dictionary, detail: String, lesson := "") -> Dictionary:
	var observation := {
		"kind": kind,
		"micro_habitat": String(conditions.get("micro_habitat", "unknown water")),
		"time_of_day": String(conditions.get("time_of_day", "unknown time")),
		"presentation": String(conditions.get("presentation", "unknown presentation")),
		"detail": detail,
		"lesson": lesson,
	}
	observations.push_front(observation)
	if observations.size() > MAX_OBSERVATIONS:
		observations.resize(MAX_OBSERVATIONS)
	return observation


func latest() -> Dictionary:
	return observations[0].duplicate(true) if not observations.is_empty() else {}


func inspect_latest() -> String:
	var observation := latest()
	if observation.is_empty():
		return "No observation to inspect yet."
	var context := "%s at %s with %s" % [
		String(observation["micro_habitat"]),
		String(observation["time_of_day"]),
		String(observation["presentation"]),
	]
	return "Observation: %s Hypothesis: %s" % [
		String(observation["detail"]),
		_hypothesis_for(observation, context),
	]


func _hypothesis_for(observation: Dictionary, context: String) -> String:
	var kind := String(observation["kind"])
	if kind == "fish sign" or kind == "lure-focused sign" or kind == "bite":
		return "Fish are active around %s; try another careful cast there." % context
	if kind == "catch":
		return "This presentation can produce a Dock Bluegill in %s." % context
	return "%s" % String(observation["lesson"])


func render() -> String:
	if observations.is_empty():
		return "Field journal:\n- No observations yet."
	var lines: Array[String] = ["Field journal:"]
	for observation in observations:
		var context := "%s · %s · %s" % [
			String(observation["micro_habitat"]),
			String(observation["time_of_day"]),
			String(observation["presentation"]),
		]
		var lesson := String(observation["lesson"])
		lines.append("- %s — %s (%s)%s" % [
			String(observation["kind"]).capitalize(),
			String(observation["detail"]),
			context,
			" Lesson: %s" % lesson if not lesson.is_empty() else "",
		])
	return "\n".join(lines)
