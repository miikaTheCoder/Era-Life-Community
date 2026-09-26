extends RefCounted
class_name IntroSceneSupport
## Intro support for the main scene. State, when needed, is passed explicitly.


static func _startup_intro_title_impact_seconds() -> float:
	return 9.28


static func _startup_intro_title_bridge_end_padding_ms() -> int:
	return 70


static func _startup_intro_initial_loading_seconds() -> float:
	return 2.6


static func _startup_intro_loading_glitch_year_fragment(target_year: String, step: int) -> String:
	var clean_year: String = str(target_year).strip_edges()
	if clean_year == "":
		clean_year = "????"

	if step <= 0:
		return "///"
	if step == 1:
		return "%s / ??" % clean_year
	if step == 2:
		return clean_year.replace(" ", " / ")

	return clean_year


static func _startup_intro_loading_glitch_line_fragment(target_line: String, step: int) -> String:
	var clean_line: String = str(target_line).strip_edges()
	if clean_line == "":
		clean_line = "history signal found"

	if step <= 0:
		return "timeline signal searching..."
	if step == 1:
		return "history buffer unstable..."
	if step == 2:
		return "%s //" % clean_line

	return clean_line


static func _startup_intro_bridge_payload_glitch_window_ms() -> int:
	return 430


static func _startup_intro_glitched_bridge_payload(beat: Dictionary, bridge_index: int, remaining_ms: int) -> Dictionary:
	var out: Dictionary = beat.duplicate(true)
	var year_text: String = str(out.get("year", "")).strip_edges()
	var line_text: String = str(out.get("line", "")).strip_edges()

	var mode: int = bridge_index % 4
	if mode == 0:
		out ["year"] = "%s / SIGNAL" % year_text
		out ["line"] = "%s • reality tearing" % line_text
	elif mode == 1:
		out ["year"] = "/// %s ///" % year_text
		out ["line"] = "%s • time stutters" % line_text
	elif mode == 2:
		out ["year"] = "%s / %s" % [year_text, "????"]
		out ["line"] = "%s • history desync" % line_text
	else:
		out ["year"] = year_text.replace("/", " / // / ")
		out ["line"] = "%s • life signal incoming" % line_text

	out ["year_color"] = Color(1.0, 0.76, 0.96, 1.0)
	out ["line_color"] = Color(0.76, 1.0, 0.96, 1.0)
	out ["pitch"] = max(float(out.get("pitch", 2.18)), 2.44)

	if remaining_ms <= 180:
		out ["year"] = "%s / ERALIFE" % str(out.get("year", ""))
		out ["line"] = "%s • glass about to break" % str(out.get("line", ""))

	return out


static func _startup_intro_positive_hash(hash_material: String) -> int:
	var value: int = int(hash(str(hash_material)))
	if value < 0:
		value = - value
	if value <= 0:
		value = 1
	return value


static func _startup_intro_ad_suffix_cutoff_year() -> int:
	return 750


static func _startup_intro_event_signature_from_line(line_text: String) -> String:
	var clean: String = str(line_text).strip_edges().to_lower()
	clean = clean.replace(".", "")
	clean = clean.replace(",", "")
	clean = clean.replace(";", "")
	clean = clean.replace(":", "")
	clean = clean.replace("  ", " ")

	if clean.begins_with("a "):
		var first_space: int = clean.find(" ")
		var second_space: int = clean.find(" ", first_space + 1)
		if second_space > 0:
			clean = clean.substr(second_space + 1).strip_edges()

	if clean.begins_with("the "):
		var first_space_the: int = clean.find(" ")
		var second_space_the: int = clean.find(" ", first_space_the + 1)
		if second_space_the > 0:
			clean = clean.substr(second_space_the + 1).strip_edges()

	return clean


static func _startup_intro_bridge_pitch_for_index(index: int) -> float:
	return min(2.72, 1.46 + (0.036 * float(index)))


static func _startup_intro_jumble_fragment_from_line(line_text: String) -> String:
	var clean: String = str(line_text).strip_edges()
	clean = clean.replace(".", "")
	clean = clean.replace(",", "")
	clean = clean.replace(";", "")
	clean = clean.replace(":", "")
	clean = clean.replace("  ", " ")

	if clean.length() > 42:
		clean = clean.substr(0, 42).strip_edges() + "..."

	return clean.to_lower()


static func _startup_intro_default_jumble_years() -> Array:
	return [
		"300 BCE",
		"44 BCE",
		"1",
		"210",
		"476",
		"620",
		"750",
		"1204",
		"1666",
		"1914",
		"1969",
		"1998",
		"2043",
		"2148",
		"3022",
		"????"
	]


static func _startup_intro_default_jumble_fragments() -> Array:
	return [
		"prodigy born",
		"artifact discovered",
		"empire fractured",
		"realm woke",
		"crown changed",
		"time forgot",
		"city prayed",
		"child inherited time",
		"boxer became champion",
		"records erased",
		"destinies folded",
		"life pushed back"
	]


static func _startup_intro_bridge_duration_for_remaining(remaining_seconds: float) -> float:
	if remaining_seconds > 3.0:
		return 0.14
	if remaining_seconds > 2.15:
		return 0.115
	if remaining_seconds > 1.25:
		return 0.09
	if remaining_seconds > 0.68:
		return 0.066
	return 0.046


static func _startup_intro_drumming_ramp_begin_seconds() -> float:
	return 4.26


static func _startup_intro_tonal_pitch_hyper_begin_seconds() -> float:
	return 6.2


static func _startup_intro_bridge_ramp_duration_for_progress(ramp_progress: float) -> float:
	var p: float = clamp(float(ramp_progress), 0.0, 1.0)
	p = p * p * (3.0 - (2.0 * p))

	var slowest_duration: float = 0.138
	var fastest_duration: float = 0.052

	return lerp(slowest_duration, fastest_duration, p)


static func _startup_intro_bridge_hyper_duration_for_remaining(remaining_seconds: float) -> float:
	if remaining_seconds > 2.45:
		return 0.046
	if remaining_seconds > 1.7:
		return 0.034
	if remaining_seconds > 0.92:
		return 0.024
	if remaining_seconds > 0.48:
		return 0.017
	return 0.012


static func _startup_intro_jumble_slot_count_for_remaining(remaining_ms: int) -> int:
	if remaining_ms < 0:
		return 4

	if remaining_ms > 330:
		return 1

	if remaining_ms > 230:
		return 2

	if remaining_ms > 130:
		return 3

	return 4


static func _startup_intro_should_glitch_bridge_payload(remaining_ms: int, hyper_active: bool) -> bool:
	if not hyper_active:
		return false

	return remaining_ms <= IntroSceneSupport._startup_intro_bridge_payload_glitch_window_ms()


static func _startup_intro_current_reality_mode_tag(gs: GameState) -> String:
	if gs != null:
		var raw_mode: String = str(gs.reality_mode).strip_edges().to_lower()
		if raw_mode != "":
			return raw_mode

	return "chaos"
